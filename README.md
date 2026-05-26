# ZIT ComfyUI RunPod image

This project builds a RunPod-friendly ComfyUI Docker image for Z-Image Turbo
generation.

- ComfyUI is updated during the Docker build so current Z-Image nodes are present.
- Z-Image Turbo split files are downloaded at Pod startup.
- Network Volume is optional.
- `/workspace/ComfyUI` is used for runtime models, inputs, and outputs.

## File map

- `Dockerfile`: custom ComfyUI image.
- `config/zit-models.json`: default BF16 Z-Image Turbo manifest.
- `config/zit-models-lowvram.json`: smaller NVFP4/FP8 manifest.
- `ZIT_PROMPTS.md`: starter prompt/settings notes.
- `scripts/start.sh`: RunPod entrypoint.
- `scripts/download_models.py`: resumable-ish model downloader with optional sha256 checks.
- `scripts/check_env.py`: torch/CUDA/pip sanity check.
- `runpod-template.env.example`: environment variables for the RunPod template.

## Included models

Default manifest:

- `models/diffusion_models/z_image_turbo_bf16.safetensors`
- `models/text_encoders/qwen_3_4b.safetensors`
- `models/vae/ae.safetensors`

Low VRAM manifest:

- `models/diffusion_models/z_image_turbo_nvfp4.safetensors`
- `models/text_encoders/qwen_3_4b_fp8_mixed.safetensors`
- `models/vae/ae.safetensors`

The Civitai page you shared points to Z-Image Turbo. For ComfyUI, this template
uses the official Comfy-Org split files because they land in the native
ComfyUI folders and avoid checkpoint-loader confusion.

## Build and push

### Recommended: GitHub Actions to GHCR

Push this directory to a GitHub repository. The included workflow publishes:

```text
ghcr.io/grawthings-beep/zit-comfyui-runpod:cuda12.8
ghcr.io/grawthings-beep/zit-comfyui-runpod:GIT_COMMIT_SHA
```

After the first run, open the package in GitHub and change visibility to
public, unless you want to configure private registry credentials in RunPod.

### Manual Docker push

```bash
docker build --platform linux/amd64 -t ghcr.io/grawthings-beep/zit-comfyui-runpod:cuda12.8 .
docker push ghcr.io/grawthings-beep/zit-comfyui-runpod:cuda12.8
```

For reproducibility, pin ComfyUI to a known commit:

```bash
docker build --platform linux/amd64 \
  --build-arg COMFYUI_REF=COMFYUI_COMMIT_SHA \
  -t ghcr.io/grawthings-beep/zit-comfyui-runpod:COMFYUI_COMMIT_SHA .
```

## RunPod template settings

- Image: `ghcr.io/grawthings-beep/zit-comfyui-runpod:cuda12.8`
- Ports: `8188/http`
- Container disk: `40 GB` or more
- Volume disk: at least `30 GB` for the default manifest
- Network Volume: leave empty when you want maximum Community Cloud GPU availability

Use `runpod-template.env.example` as the environment variable checklist.

## Model manifest

Default:

```text
MODEL_MANIFEST_URL=https://raw.githubusercontent.com/grawthings-beep/zit-comfyui-runpod/main/config/zit-models.json
```

Low VRAM:

```text
MODEL_MANIFEST_URL=https://raw.githubusercontent.com/grawthings-beep/zit-comfyui-runpod/main/config/zit-models-lowvram.json
```

By default, the bundled manifest is copied to `/workspace/config/models.json` on
each boot (`MODEL_MANIFEST_REFRESH=1`) so stale manifests left on a persistent
volume do not override image updates. Set `MODEL_MANIFEST_REFRESH=0` only when
you intentionally manage `/workspace/config/models.json` yourself.

Relative manifest `path` values are written under `/workspace/ComfyUI`.

## Dependency check

Set `RUN_DEP_CHECK=1` in the template. On startup it prints:

- Python path
- torch version
- CUDA version
- visible GPU name
- `pip check` result

The startup command enables CORS with `COMFYUI_CORS_ORIGIN=*` by default so
ComfyUI can work behind the RunPod HTTP proxy.

## References

- Z-Image Turbo Civitai page: https://civitai.com/models/2168935
- Official ComfyUI split files: https://huggingface.co/Comfy-Org/z_image_turbo/tree/main/split_files
- ComfyUI Z-Image Turbo guide: https://docs.comfy.org/tutorials/image/z-image/z-image-turbo
