#!/usr/bin/env bash
set -Eeuo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-/opt/ComfyUI}"
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace/ComfyUI}"
MODEL_ROOT="${MODEL_ROOT:-${WORKSPACE_DIR}}"
CONFIG_DIR="${CONFIG_DIR:-/workspace/config}"
MODEL_MANIFEST="${MODEL_MANIFEST:-${CONFIG_DIR}/models.json}"
DEFAULT_MODEL_MANIFEST="${DEFAULT_MODEL_MANIFEST:-/opt/runpod-comfy/config/zit-models.json}"
MODEL_MANIFEST_REFRESH="${MODEL_MANIFEST_REFRESH:-1}"
PORT="${PORT:-8188}"
LISTEN="${LISTEN:-0.0.0.0}"
PYTHON_BIN="${PYTHON_BIN:-$(command -v python || command -v python3 || command -v python3.12)}"

mkdir -p "${WORKSPACE_DIR}/input" \
         "${WORKSPACE_DIR}/output" \
         "${MODEL_ROOT}/models/checkpoints" \
         "${MODEL_ROOT}/models/diffusion_models" \
         "${MODEL_ROOT}/models/loras" \
         "${MODEL_ROOT}/models/text_encoders" \
         "${MODEL_ROOT}/models/vae" \
         "${MODEL_ROOT}/models/vae_approx" \
         "${MODEL_ROOT}/models/clip" \
         "${MODEL_ROOT}/models/unet" \
         "${MODEL_ROOT}/models/model_patches" \
         "${MODEL_ROOT}/models/controlnet" \
         "${CONFIG_DIR}"

cat > "${COMFYUI_DIR}/extra_model_paths.yaml" <<YAML
workspace:
  base_path: ${MODEL_ROOT}
  checkpoints: models/checkpoints/
  clip: models/clip/
  clip_vision: models/clip_vision/
  configs: models/configs/
  controlnet: models/controlnet/
  diffusion_models: models/diffusion_models/
  embeddings: models/embeddings/
  loras: models/loras/
  model_patches: models/model_patches/
  style_models: models/style_models/
  text_encoders: models/text_encoders/
  unet: models/unet/
  upscale_models: models/upscale_models/
  vae: models/vae/
  vae_approx: models/vae_approx/
YAML

if [[ -n "${MODEL_MANIFEST_JSON:-}" ]]; then
  printf '%s' "${MODEL_MANIFEST_JSON}" > "${MODEL_MANIFEST}"
elif [[ -n "${MODEL_MANIFEST_URL:-}" ]]; then
  curl -fsSL "${MODEL_MANIFEST_URL}" -o "${MODEL_MANIFEST}"
elif [[ -f "${DEFAULT_MODEL_MANIFEST}" ]]; then
  if [[ "${MODEL_MANIFEST_REFRESH}" == "1" || ! -f "${MODEL_MANIFEST}" ]]; then
    cp "${DEFAULT_MODEL_MANIFEST}" "${MODEL_MANIFEST}"
    echo "Synced bundled model manifest: ${DEFAULT_MODEL_MANIFEST} -> ${MODEL_MANIFEST}"
  else
    echo "Using existing model manifest: ${MODEL_MANIFEST}"
  fi
fi

if [[ -f "${MODEL_MANIFEST}" ]]; then
  "${PYTHON_BIN}" /opt/runpod-comfy/scripts/download_models.py \
    --manifest "${MODEL_MANIFEST}" \
    --root "${MODEL_ROOT}"
else
  echo "No model manifest found at ${MODEL_MANIFEST}; starting without model downloads."
fi

if [[ "${RUN_DEP_CHECK:-0}" == "1" ]]; then
  "${PYTHON_BIN}" /opt/runpod-comfy/scripts/check_env.py --comfyui-dir "${COMFYUI_DIR}"
fi

cd "${COMFYUI_DIR}"
exec "${PYTHON_BIN}" main.py \
  --listen "${LISTEN}" \
  --port "${PORT}" \
  --enable-cors-header "${COMFYUI_CORS_ORIGIN:-*}" \
  --input-directory "${WORKSPACE_DIR}/input" \
  --output-directory "${WORKSPACE_DIR}/output" \
  ${COMFYUI_ARGS:-}
