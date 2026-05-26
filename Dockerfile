# syntax=docker/dockerfile:1.7

# Verification image: inherit RunPod's ComfyUI stack directly, then replace only
# startup/model-download behavior with this repo's lightweight RunPod flow.
ARG BASE_IMAGE=runpod/comfyui:latest
ARG COMFYUI_REF=master

FROM ${BASE_IMAGE}

ARG COMFYUI_REF=master

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HF_XET_HIGH_PERFORMANCE=1 \
    COMFYUI_DIR=/opt/comfyui-baked

COPY config/ /opt/runpod-comfy/config/
COPY scripts/ /opt/runpod-comfy/scripts/
COPY requirements-runtime.txt custom_nodes.txt /opt/runpod-comfy/
RUN set -eux; \
    if command -v apt-get >/dev/null 2>&1; then \
      apt-get update; \
      apt-get install -y --no-install-recommends git ca-certificates; \
      rm -rf /var/lib/apt/lists/*; \
    fi; \
    rm -rf "${COMFYUI_DIR}"; \
    git clone --depth 1 --branch "${COMFYUI_REF}" https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"; \
    python3 -m pip install --no-cache-dir -r /opt/runpod-comfy/requirements-runtime.txt; \
    python3 -m pip install --no-cache-dir -r "${COMFYUI_DIR}/requirements.txt"; \
    chmod +x /opt/runpod-comfy/scripts/*.sh

WORKDIR /opt/comfyui-baked
EXPOSE 8188

ENTRYPOINT ["/opt/runpod-comfy/scripts/start.sh"]
