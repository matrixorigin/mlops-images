## 镜像发布流程
如果有新的工具镜像需要发布到 Neolink.AI，需要按照如下流程进行镜像发布。

### 1. 准备镜像
参考目前已有的工具镜像，比如 https://github.com/matrixorigin/mlops-images/tree/main/pytorch，进行镜像的构建，注意以下事项：

1. 一般工具镜像都包括 SSH 登录，以便用户可以登录或者进行文件传输

2. 镜像内启动的进程，一般通过 supervisor 管理，以便在系统重启或者其他异常情况时自动重启。进程启动内容写入/etc/supervisord/supervisor-other.ini，进程日志放在/tmp

3. 镜像内启动的服务，一般监听 0.0.0.0 地址，以便外部可以访问，也可以通过 Ingress 暴露

4. 如果对外部数据有依赖，建议放一下数据的地址，让用户在启动后下载到存储卷，尽量减少镜像自身的体积。数据如果放到了存储卷的挂载路径，在创建实例挂载存储卷时会把此目录覆盖，需要重新映射

5. 参考 Docker 镜像的最佳实践，尽量减少镜像层及镜像的大小，以便提高镜像的下载速度

6. 镜像名称和tag，需要体现核心服务版本以及python版本、cuda版本、操作系统版本，例如：ollama-webui:ollama0.3.11-python3.11-cuda12.1.0-runtime-ubuntu22.04

7. 如果对环境变量有依赖，需要确保SSH登录后能读到此环境变量。建议将环境变量写入/etc/profile

### 2. 测试
1. 在 Neolink.AI 支持自定义路由之前，需要告知 Neolink.AI 的维护人员，添加特定镜像创建容器实例时，需要的对外服务端口，格式如下：
```yaml
      - imageNames: ["ollama-webui"] # 镜像的名字，仅需要 image name 部分，这里的镜像完整地址为：images.neolink-ai.com/matrixdc/ollama-webui:python3.10-cuda12.1.0-cudnn8-devel-ubuntu22.04
        type: ingress # 默认值即可
        httpRules: # 7 层 HTTP 服务
          - port: 11434 # 内部服务的端口
            name: Ollama # 显示到产品“内置工具”的名字
            path: / # 对外的访问路径
          - port: 8888
            name: Jupyterlab
            path: /jupyter
          - port: 6006
            name: Tensorboard
            path: /monitor
        tcpRules: # 4 层 TCP，目前主要是 SSH 端口，如果支持，默认填上即可
          - port: 22
            name: SSH
```

* 注意：后续 Neolink.AI 支持自定义路由后，此步骤可以忽略，可以直接进行第 2 步，但是需要在创建实例后，在平台上进行 ingress 路由的定义，并测试内部服务是否可以正常访问。

2. 将镜像推送到自己的私有镜像仓库

3. 待维护人员更新对应的 ingress 模版后，就可以在 Neolink.AI 平台上创建容器实例，选择私有镜像，点击创建和验证

4. 开发自验通过后，提测给QA

### 3. 镜像提测
1. 提测时，需要镜像owner创建对应测试任务issue（neolink.ai项目下），issue提供提测物料：线上的镜像地址、镜像所在私有账户信息、镜像暴漏的服务访问信息、验证文档、demo，写清楚怎样验证，测试按照验证文档及demo进行验证。

2. 提测前需要镜像owner自验通过（这里的自验通过指的是使用该镜像创建实例流程、访问服务、demo使用是ok的，并不是本地docker run，用户不关心docke run场景） 

3. 镜像owner自验过程中如果涉及到mdc环境相关的，镜像owner找Neolink.AI 维护人员协调。 

4. 提测方式：由镜像owner约会议showcase（参会方：涉及到的开发、产品、测试人员）。

5. 进入测试的标准： （1）提测issue就绪，提测物料已提供。（2）showcase主流程通过。此2项全部满足后方进入测试侧，否则退回到镜像owner侧。 

6. 测试中问题跟踪：属于bug类的，由测试owner在neolink.ai创建bug issue，指派给镜像owner。


### 4. 发布
1. QA测试通过后，走mdc发布流程，告知 Neolink.AI 的维护人员，提供上面已经验证通过的镜像地址

2. 维护人员会将镜像同步到 matrixdc 的仓库组，完成工具镜像的发布

### 5. Neolink.AI 维护人员
* 李恩志
* 宋荣祥
* 王磊

