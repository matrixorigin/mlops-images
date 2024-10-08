ARG BASE_IMAGE

FROM ${BASE_IMAGE}

ADD --chown=ray:users https://raw.githubusercontent.com/ray-project/kuberay/refs/tags/v1.2.1/ray-operator/config/samples/vllm/serve.py /home/ray/serve.py

ARG MODEL
RUN git lfs install && \
    git clone https://hf-mirror.com/${MODEL}
