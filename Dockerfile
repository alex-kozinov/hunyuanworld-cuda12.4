# ---- Base: CUDA 12.4 + Ubuntu 22.04 ----
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    HF_HUB_ENABLE_HF_TRANSFER=1 \
    PYTHONUNBUFFERED=1

# ---- System deps ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3-pip python3-dev python3-venv \
    git curl wget ca-certificates \
    libgl1 libglib2.0-0 ffmpeg \
    build-essential pkg-config \
    tini \
    && rm -rf /var/lib/apt/lists/*

# link `python` -> python3
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 && \
    python -m pip install --upgrade pip

# ---- Workdir & project ----
WORKDIR /workspace
# если репо уже у тебя локально рядом с Dockerfile — лучше COPY:
# COPY HunyuanWorld-Mirror /workspace/HunyuanWorld-Mirror
# COPY requirements.txt /workspace/HunyuanWorld-Mirror/requirements.txt
# иначе клонируем внутри образа:
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

# (опционально) НЕ тянем чекпойнты в образ, чтобы он не раздулся:
# RUN huggingface-cli download tencent/HunyuanWorld-Mirror --local-dir ./ckpts

EXPOSE 8888
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["bash", "-lc", "jupyter lab --no-browser --ip=0.0.0.0 --port=8888 --allow-root --ServerApp.allow_origin='*' --ServerApp.disable_check_xsrf=True"]
