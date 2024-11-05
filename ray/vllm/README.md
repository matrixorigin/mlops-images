## Serve a Large Language Model with vLLM

来自ray社区的官方示例：
[Serve a Large Language Model with vLLM](https://docs.ray.io/en/latest/serve/tutorials/vllm-example.html)

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
  name: rayservice-vllm
spec:
  # serveConfigV2 takes a yaml multi-line scalar, which should be a Ray Serve multi-application config. See https://docs.ray.io/en/latest/serve/multi-app.html.
  serveConfigV2: |
    applications:
    - name: llm
      route_prefix: /
      import_path: serve:model
      deployments:
      - name: VLLMDeployment
        num_replicas: 1
        ray_actor_options:
          num_cpus: 1
          # NOTE: num_gpus is set automatically based on TENSOR_PARALLELISM
      runtime_env:
        env_vars:
          #HF_ENDPOINT: "https://hf-mirror.com"
          MODEL_ID: "/home/ray/Qwen2-0.5B-Instruct"
          TENSOR_PARALLELISM: "1"
          VLLM_CPU_KVCACHE_SPACE: "1"
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
            image: ghcr.io/bincherry/ray:2.35.0-py310-cpu-vllm
            imagePullPolicy: Always
            resources:
              limits:
                cpu: 1
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
              image: ghcr.io/bincherry/ray:2.35.0-py310-cpu-vllm-qwen_qwen2_0_5b_instruct
              imagePullPolicy: Always
              lifecycle:
                preStop:
                  exec:
                    command: ["/bin/sh","-c","ray stop"]
              resources:
                limits:
                  cpu: "1"
                  memory: "4Gi"
                requests:
                  cpu: "0.1"
                  memory: 128Mi
```

### Client request

```shell
curl 10.105.138.53:8000/v1/chat/completions -X POST -H "Content-Type: application/json" -d '{
  "model": "Qwen/Qwen2-0.5B-Instruct",
  "messages": [
    {
      "role": "system",
      "content": "您是足球专家"
    },
    {
      "role": "user",
      "content": "谁赢得了2018年的FIFA世界杯？"
    }
  ]
}'
```
