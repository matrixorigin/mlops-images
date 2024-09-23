# 学习使用megatron-lm 

## 1. 准备数据
```
分词数据来源以及 加训练的训练数据来源于
wget https://huggingface.co/bigscience/misc-test-data/resolve/main/stas/oscar-1GB.jsonl.xz
wget https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-vocab.json
wget https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt
```

## 2. 准备镜像环境
```
docker run -dt --name nvidia_pytorch_env --restart=always --gpus all --network=host --shm-size 16G -v /workspace:/workspace -w /workspace harbor.43.143.130.168.nip.io:30443/system-train/pytorch:23.04-py3-09181814 /bin/bash
docker exec -it nvidia_pytorch_env bash
# 这部分，如果是h100的节点，网络连接不通顺的情况，包括第一步的数据准备阶段，请预先在挂载磁盘下下载好，直接挂载使用
root@instance-cb3f57da-mqjp9:/workspace# git clone https://github.com/NVIDIA/Megatron-LM.git
root@instance-cb3f57da-mqjp9:/workspace# cd Megatron-LM
root@instance-cb3f57da-mqjp9:/workspace/Megatron-LM# git checkout core_r0.8.0
```

## 3. 数据处理
```
# 其中 /workspace 是挂载的目录，目录说明
root@instance-cb3f57da-mqjp9:/workspace/model# tree 
.
├── gpt2-vocab
│   ├── gpt2-merges.txt
│   └── gpt2-vocab.json
└── megatron-models
    └── 345m-1dp-out

root@instance-cb3f57da-mqjp9:/workspace/Megatron-LM# python tools/preprocess_data.py \
--input /workspace/data/oscar-1GB.jsonl \
--output-prefix /workspace/data/my-gpt2 \
--vocab-file /workspace/model/gpt2-vocab/gpt2-vocab.json \
--dataset-impl mmap \
--tokenizer-type GPT2BPETokenizer \
--merge-file /workspace/model/gpt2-vocab/gpt2-merges.txt \
--append-eod \
--workers 20 \
--chunk-size 25

root@instance-cb3f57da-mqjp9:/workspace/data# tree
.
├── my-gpt2_text_document.bin
└── my-gpt2_text_document.idx

```

## 4. 训练脚本以及训练模型
```
root@instance-cb3f57da-mqjp9:/workspace/Megatron-LM# cat examples/gpt3/train_gpt2_345m_1dp1pp_distributed.sh 

#!/bin/bash

# Runs the "345M" parameter model

export CUDA_DEVICE_MAX_CONNECTIONS=1

GPUS_PER_NODE=4
# Change for multinode config
MASTER_ADDR=localhost
MASTER_PORT=6000
NUM_NODES=1
NODE_RANK=0
WORLD_SIZE=$(($GPUS_PER_NODE*$NUM_NODES))

CHECKPOINT_PATH=/workspace/model/megatron-models/345m-1dp-out
TENSORBOARD_LOGS_PATH=/workspace/tensorboard_logs
VOCAB_FILE=/workspace/model/gpt2-vocab/gpt2-vocab.json
MERGE_FILE=/workspace/model/gpt2-vocab/gpt2-merges.txt
DATA_PATH=/workspace/data/my-gpt2_text_document

DISTRIBUTED_ARGS="
    --nproc_per_node $GPUS_PER_NODE \
    --nnodes $NUM_NODES \
    --master_addr $MASTER_ADDR \
    --master_port $MASTER_PORT 
"

GPT_MODEL_ARGS="
    --num-layers 24 \
    --hidden-size 1024 \
    --num-attention-heads 16 \
    --seq-length 1024 \
    --max-position-embeddings 1024 \
    --attention-softmax-in-fp32 
"

# 因为 tensor-model-parallel-size 1 pipeline-model-parallel-size 1 而且 GPUS_PER_NODE=4 
# 评估出来的data parallel size 是 4
# global-batch-size必须是 micro-batch-size * data parallel size 的整数倍

TRAINING_ARGS="
    --micro-batch-size 4 \
    --global-batch-size 32 \
    --train-iters 3000 \
    --weight-decay 0.1 \
    --init-method-std 0.006 \
    --clip-grad 1.0 \
    --fp16 \
    --lr 6.0e-5 \
    --lr-decay-style cosine \
    --min-lr 6.0e-6 \
    --lr-warmup-fraction .001 \
    --lr-decay-iters 430000 
"

# 不进行模型并行
# 这里使用的是 1dp 1pp 4gpus 
MODEL_PARALLEL_ARGS="
        --tensor-model-parallel-size 1 \
        --pipeline-model-parallel-size 1 
"

DATA_ARGS="
    --data-path $DATA_PATH \
    --vocab-file $VOCAB_FILE \
    --merge-file $MERGE_FILE \
    --split 949,50,1 
"

EVAL_AND_LOGGING_ARGS="
    --log-interval 100 \
    --save-interval 1000 \
    --eval-interval 1000 \
    --save $CHECKPOINT_PATH \
    --load $CHECKPOINT_PATH \
    --eval-iters 10 \
    --tensorboard-dir $TENSORBOARD_LOGS_PATH
" 

torchrun ${DISTRIBUTED_ARGS} pretrain_gpt.py \
    ${GPT_MODEL_ARGS} \
    ${TRAINING_ARGS} \
    ${MODEL_PARALLEL_ARGS} \
    ${DATA_ARGS} \
    ${EVAL_AND_LOGGING_ARGS}
```
运行脚本
```
root@instance-cb3f57da-mqjp9:/workspace/Megatron-LM# bash examples/gpt3/train_gpt2_345m_1dp1pp_distributed.sh 
``` 
模型输出
```
root@instance-cb3f57da-mqjp9:/workspace/model/megatron-models/345m-1dp-out# tree
.
├── iter_0001000
│   └── mp_rank_00
│       └── model_optim_rng.pt
├── iter_0002000
│   └── mp_rank_00
│       └── model_optim_rng.pt
├── iter_0003000
│   └── mp_rank_00
│       └── model_optim_rng.pt
└── latest_checkpointed_iteration.txt
```

## 5. 评估模型

## 6. 使用模型
```
1、模型脚本路径信息
root@instance-cb3f57da-mqjp9:/workspace/Megatron-LM# cat examples/inference/run_text_generation_server_345M.sh 
#!/bin/bash
# This example will start serving the 345M model.
DISTRIBUTED_ARGS="--nproc_per_node 1 \
                  --nnodes 1 \
                  --node_rank 0 \
                  --master_addr localhost \
                  --master_port 6000"

CHECKPOINT=/workspace/model/megatron-models/345m-1dp-out
VOCAB_FILE=/workspace/model/gpt2-vocab/gpt2-vocab.json
MERGE_FILE=/workspace/model/gpt2-vocab/gpt2-merges.txt

export CUDA_DEVICE_MAX_CONNECTIONS=1

# 这行代码已经打包到镜像中，注释掉
# pip install flask-restful 

torchrun $DISTRIBUTED_ARGS tools/run_text_generation_server.py   \
       --tensor-model-parallel-size 1  \
       --pipeline-model-parallel-size 1  \
       --num-layers 24  \
       --hidden-size 1024  \
       --load ${CHECKPOINT}  \
       --num-attention-heads 16  \
       --max-position-embeddings 1024  \
       --tokenizer-type GPT2BPETokenizer  \
       --fp16  \
       --micro-batch-size 1  \
       --seq-length 1024  \
       --vocab-file $VOCAB_FILE  \
       --merge-file $MERGE_FILE  \
       --seed 42
3、模型运行
Megatron-LM# sh examples/inference/run_text_generation_server_345M.sh
4、模型推理输入
Megatron-LM# python tools/text_generation_cli.py 127.0.0.1:5000

```