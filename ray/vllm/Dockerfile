ARG BASE_IMAGE

FROM ${BASE_IMAGE}

ARG MODEL

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends git git-lfs && \
    git lfs install && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER ray

RUN git clone https://hf-mirror.com/${MODEL}
