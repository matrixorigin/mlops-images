## serve_config_examples

来自ray社区的官方示例：
- 推理服务代码 [serve_config_examples](https://github.com/ray-project/serve_config_examples)
- 如何部署到k8s [Deploy on Kubernetes](https://docs.ray.io/en/latest/serve/production-guide/kubernetes.html)

其中官方示例中的`text_ml.py`不兼容新版的rayserve，这里做了一点修改。

### Deploy as RayService

```yaml
# Make sure to increase resource requests and limits before using this example in production.
# For examples with more realistic resource configuration, see
# ray-cluster.complete.large.yaml and
# ray-cluster.autoscaler.large.yaml.
apiVersion: ray.io/v1
kind: RayService
metadata:
  annotations:
    neolink.ai/istio-dashboard-allow-user: "user@example.com"
    neolink.ai/istio-dashboard-unprotected: "true"
    neolink.ai/istio-gateway: "istio-system/ray-ingressgateway"
    neolink.ai/istio-domain: "10.161.0.67.nip.io"
    neolink.ai/istio-gateway-port: "31680"
  name: rayservice-sample
spec:
  # serveConfigV2 takes a yaml multi-line scalar, which should be a Ray Serve multi-application config. See https://docs.ray.io/en/latest/serve/multi-app.html.
  serveConfigV2: |
    applications:
      - name: text_ml_app
        import_path: text_ml.app
        route_prefix: /summarize_translate
        runtime_env:
          env_vars:
            HF_ENDPOINT: "https://hf-mirror.com"
        deployments:
          - name: Translator
            num_replicas: 1
            ray_actor_options:
              num_cpus: 0.2
            user_config:
              language: french
          - name: Summarizer
            num_replicas: 1
            ray_actor_options:
              num_cpus: 0.2
  rayClusterConfig:
    rayVersion: '2.35.0' # should match the Ray version in the image of the containers
    ######################headGroupSpecs#################################
    # Ray head pod template.
    headGroupSpec:
      # The `rayStartParams` are used to configure the `ray start` command.
      # See https://github.com/ray-project/kuberay/blob/master/docs/guidance/rayStartParams.md for the default settings of `rayStartParams` in KubeRay.
      # See https://docs.ray.io/en/latest/cluster/cli.html#ray-start for all available options in `rayStartParams`.
      rayStartParams:
        dashboard-host: '0.0.0.0'
        num-cpus: '0'
      #pod template
      template:
        metadata:
          annotations:
            sidecar.istio.io/inject: "true"
        spec:
          containers:
            - name: ray-head
              image: ghcr.io/bincherry/ray:text_ml
              imagePullPolicy: Always
              resources:
                limits:
                  cpu: 2
                  memory: 2Gi
                requests:
                  cpu: "0.1"
                  memory: 128Mi
              ports:
                - containerPort: 6379
                  name: gcs-server
                - containerPort: 8265 # Ray dashboard
                  name: dashboard
                - containerPort: 10001
                  name: client
                - containerPort: 8000
                  name: serve
    workerGroupSpecs:
      # the pod replicas in this group typed worker
      - replicas: 1
        minReplicas: 1
        maxReplicas: 5
        # logical group name, for this called small-group, also can be functional
        groupName: cpu1
        # The `rayStartParams` are used to configure the `ray start` command.
        # See https://github.com/ray-project/kuberay/blob/master/docs/guidance/rayStartParams.md for the default settings of `rayStartParams` in KubeRay.
        # See https://docs.ray.io/en/latest/cluster/cli.html#ray-start for all available options in `rayStartParams`.
        rayStartParams:
          num-cpus: "1"
        #pod template
        template:
          spec:
            containers:
              - name: ray-worker # must consist of lower case alphanumeric characters or '-', and must start and end with an alphanumeric character (e.g. 'my-name',  or '123-abc'
                image: ghcr.io/bincherry/ray:text_ml
                lifecycle:
                  preStop:
                    exec:
                      command: ["/bin/sh","-c","ray stop"]
                resources:
                  limits:
                    cpu: "1"
                    memory: "2Gi"
                  requests:
                    cpu: "0.1"
                    memory: 128Mi
```

### Client request

```shell
curl -X POST -H "Content-Type: application/json" 10.109.48.227:8000/summarize_translate -d '"Hello, how are you?"'
```
