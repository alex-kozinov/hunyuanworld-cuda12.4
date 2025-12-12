# ---- Base: CUDA 12.4 + Ubuntu 22.04 ----
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    HF_HUB_ENABLE_HF_TRANSFER=1 \
    PYTHONUNBUFFERED=1

# ---- System deps ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3-pip python3-dev python3-venv \
    git tmux wget curl ca-certificates openssh-server nginx \
    libgl1 libglib2.0-0 ffmpeg \
    build-essential pkg-config \
    tini \
    && rm -rf /var/lib/apt/lists/*

# link `python` -> python3
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 && \
    python -m pip install --upgrade pip

# Prepare host (SSH, NGINX)
RUN rm -f /etc/ssh/ssh_host_*

# NGINX Proxy
COPY proxy/nginx.conf /etc/nginx/nginx.conf
COPY proxy/readme.html /usr/share/nginx/html/readme.html


# ---- Workdir & project ----
WORKDIR /workspace
RUN git clone https://github.com/Tencent-Hunyuan/HunyuanWorld-Mirror.git /workspace/HunyuanWorld-Mirror
WORKDIR /workspace/HunyuanWorld-Mirror

# ---- Python deps (по твоей истории) ----
# 1) Torch cu124 (официальный индекс)
RUN python -m pip install torch==2.4.0 torchvision==0.19.0 \
    --index-url https://download.pytorch.org/whl/cu124

# 2) requirements из репозитория
RUN python -m pip install -r requirements.txt

# 3) gsplat с их индексом
RUN python -m pip install gsplat --index-url https://docs.gsplat.studio/whl/pt24cu124

# 4) HF CLI + ускоренная загрузка
RUN python -m pip install -U "huggingface_hub[cli]==0.25.2" hf-transfer

# 5) JupyterLab + kernel, чтобы сразу готово
RUN python -m pip install jupyterlab ipykernel && \
    python -m ipykernel install --user --name py310 --display-name "Python 3.10 (CUDA 12.4)"

# Start Script
COPY scripts/start.sh /start.sh
RUN chmod 755 /start.sh
WORKDIR /workspace
CMD ["/start.sh"]
