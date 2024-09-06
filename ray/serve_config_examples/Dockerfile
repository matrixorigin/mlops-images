FROM rayproject/ray:2.35.0-py310-cpu

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends git git-lfs && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    pip install torch --no-cache-dir -c /home/ray/requirements_compiled.txt && \
    pip install transformers --no-cache-dir -c /home/ray/requirements_compiled.txt && \
    apt-get purge -y build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER ray

RUN git clone https://hf-mirror.com/google-t5/t5-small
ADD --chown=ray:users text_ml.py /home/ray/text_ml.py

WORKDIR /home/ray
