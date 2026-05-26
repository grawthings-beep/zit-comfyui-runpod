# GHCR + RunPod Steps

## 1. Create a GitHub repository

Create a new repository on GitHub.

- Repository name: `zit-comfyui-runpod`
- Visibility: public or private is OK
- Do not add README or .gitignore from GitHub

## 2. Push this directory to GitHub

Run these commands in PowerShell:

```powershell
cd C:\Users\grawt\Documents\Codex\2026-05-17\runpod-comunity-cloud-lora-comfyui-latest\zit-comfyui-runpod

git init
git branch -M main
git add .
git commit -m "Add ZIT ComfyUI RunPod template"
git remote add origin https://github.com/grawthings-beep/zit-comfyui-runpod.git
git push -u origin main
```

If Git complains about ownership:

```powershell
git config --global --add safe.directory C:/Users/grawt/Documents/Codex/2026-05-17/runpod-comunity-cloud-lora-comfyui-latest/zit-comfyui-runpod
```

## 3. Build the image with GitHub Actions

Open the repository on GitHub:

1. Open `Actions`.
2. Select `Build GHCR image`.
3. Click `Run workflow` if it did not run automatically.
4. Wait for the workflow to finish.

The workflow publishes:

```text
ghcr.io/grawthings-beep/zit-comfyui-runpod:cuda12.8
```

## 4. Make the GHCR package public

After the first push:

1. Open your GitHub profile.
2. Open `Packages`.
3. Open `zit-comfyui-runpod`.
4. Open `Package settings`.
5. Use `Change visibility` and select `Public`.

Public packages can be pulled by RunPod without registry credentials.

## 5. Create a RunPod template

In RunPod Console, open `Templates` and create a new template.

- Container Image: `ghcr.io/grawthings-beep/zit-comfyui-runpod:cuda12.8`
- Container Disk: `40 GB` or more
- Volume Disk: `30 GB` or more for default models
- HTTP Port: `8188`
- Start Command: leave empty

Leave Network Volume empty when you want maximum Community Cloud GPU availability.

## 6. Add environment variables

Minimum:

```text
PORT=8188
LISTEN=0.0.0.0
RUN_DEP_CHECK=1
COMFYUI_CORS_ORIGIN=*
MODEL_MANIFEST_REFRESH=1
MODEL_MANIFEST_URL=https://raw.githubusercontent.com/grawthings-beep/zit-comfyui-runpod/main/config/zit-models.json
MODEL_MANIFEST_JSON=
COMFYUI_ARGS=
```

For lower VRAM:

```text
MODEL_MANIFEST_URL=https://raw.githubusercontent.com/grawthings-beep/zit-comfyui-runpod/main/config/zit-models-lowvram.json
```

## 7. Deploy on Community Cloud

Deploy a Pod using the template. In the logs, confirm:

- Docker image pull completed
- Model downloads completed
- `cuda_available: True`
- GPU name is printed
- ComfyUI starts on port `8188`

Open the RunPod HTTP service for port `8188`.
