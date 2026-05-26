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
    python -m pip install --no-cache-dir -r /opt/runpod-comfy/requirements-runtime.txt; \
    if [ -d "${COMFYUI_DIR}/.git" ]; then \
      git -C "${COMFYUI_DIR}" fetch --depth 1 origin "${COMFYUI_REF}"; \
      git -C "${COMFYUI_DIR}" checkout FETCH_HEAD; \
      python -m pip install --no-cache-dir -r "${COMFYUI_DIR}/requirements.txt"; \
    fi; \
    chmod +x /opt/runpod-comfy/scripts/*.sh

WORKDIR /opt/comfyui-baked
EXPOSE 8188

ENTRYPOINT ["/opt/runpod-comfy/scripts/start.sh"]
