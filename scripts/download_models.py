#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.request


CHUNK_SIZE = 1024 * 1024 * 8


def expand(value):
    if value is None:
        return None
    if isinstance(value, str):
        return os.path.expandvars(value)
    if isinstance(value, dict):
        return {k: expand(v) for k, v in value.items()}
    if isinstance(value, list):
        return [expand(v) for v in value]
    return value


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(CHUNK_SIZE), b""):
            digest.update(chunk)
    return digest.hexdigest()


def is_valid_existing(path: pathlib.Path, expected_sha256: str | None) -> bool:
    if not path.exists() or path.stat().st_size == 0:
        return False
    if not expected_sha256:
        return True
    actual = sha256_file(path)
    return actual.lower() == expected_sha256.lower()


def make_request(url: str, headers: dict[str, str], start_at: int):
    request_headers = {
        "User-Agent": "Mozilla/5.0 (compatible; runpod-comfyui-downloader/1.0)",
        "Accept": "*/*",
    }
    request_headers.update(headers)
    if start_at > 0:
        request_headers["Range"] = f"bytes={start_at}-"
    return urllib.request.Request(url, headers=request_headers)


def download(url: str, dest: pathlib.Path, headers: dict[str, str], retries: int) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    partial = dest.with_suffix(dest.suffix + ".part")

    for attempt in range(1, retries + 1):
        resume_at = partial.stat().st_size if partial.exists() else 0
        request = make_request(url, headers, resume_at)

        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                status = getattr(response, "status", 200)
                mode = "ab" if resume_at > 0 and status == 206 else "wb"
                if mode == "wb" and partial.exists():
                    partial.unlink()

                total = response.headers.get("Content-Length", "?")
                print(f"Downloading {dest.name} ({total} bytes reported)")
                with partial.open(mode + "") as handle:
                    last_log = time.monotonic()
                    while True:
                        chunk = response.read(CHUNK_SIZE)
                        if not chunk:
                            break
                        handle.write(chunk)
                        now = time.monotonic()
                        if now - last_log > 10:
                            mb = partial.stat().st_size / 1024 / 1024
                            print(f"  {dest.name}: {mb:.1f} MiB")
                            last_log = now

            partial.replace(dest)
            return
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            if attempt >= retries:
                raise
            wait = min(30, 2**attempt)
            print(f"Download failed for {dest.name}: {exc}; retrying in {wait}s")
            time.sleep(wait)


def load_manifest(path: pathlib.Path) -> list[dict]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get("models"), list):
        return data["models"]
    raise ValueError("Manifest must be a list or an object with a 'models' list.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Download ComfyUI models from a JSON manifest.")
    parser.add_argument("--manifest", required=True, help="Path to models.json")
    parser.add_argument("--root", default="/workspace/ComfyUI", help="Root for relative destination paths")
    parser.add_argument("--retries", type=int, default=int(os.getenv("MODEL_DOWNLOAD_RETRIES", "4")))
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    manifest_path = pathlib.Path(args.manifest)
    root = pathlib.Path(args.root)
    entries = load_manifest(manifest_path)

    failures = 0
    for raw_entry in entries:
        entry = expand(raw_entry)
        name = entry.get("name") or entry.get("path") or "unnamed"
        enabled = bool(entry.get("enabled", True))
        required = bool(entry.get("required", True))

        if not enabled:
            print(f"Skipping disabled model: {name}")
            continue

        url = entry.get("url")
        rel_path = entry.get("path")
        expected_sha256 = (entry.get("sha256") or "").strip() or None
        headers = entry.get("headers") or {}

        unresolved_headers = [
            key for key, value in headers.items()
            if isinstance(value, str) and "$" in value
        ]

        if not url or "$" in url or unresolved_headers:
            if unresolved_headers:
                header_names = ", ".join(unresolved_headers)
                message = f"headers contain unresolved env vars for {name}: {header_names}"
            else:
                message = f"URL is missing or contains an unresolved env var for {name}"
            if required:
                print(f"ERROR: {message}", file=sys.stderr)
                failures += 1
            else:
                print(f"Skipping optional model: {message}")
            continue

        if not rel_path:
            print(f"ERROR: path is missing for {name}", file=sys.stderr)
            failures += 1
            continue

        dest = pathlib.Path(rel_path)
        if not dest.is_absolute():
            dest = root / dest

        if is_valid_existing(dest, expected_sha256):
            print(f"Already present: {dest}")
            continue

        if args.dry_run:
            print(f"Would download {name} -> {dest}")
            continue

        try:
            download(url, dest, headers, args.retries)
            if expected_sha256 and not is_valid_existing(dest, expected_sha256):
                raise ValueError(f"sha256 mismatch for {dest}")
            print(f"Ready: {dest}")
        except Exception as exc:
            prefix = "ERROR" if required else "WARNING"
            print(f"{prefix}: failed to download {name}: {exc}", file=sys.stderr)
            if required:
                failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
