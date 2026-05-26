# ZIT Prompt Notes

Z-Image Turbo is prompt-sensitive in a normal natural-language way. Start with
short, specific English prompts, then add style and camera details.

## Positive starter

```text
anime illustration, a stylish girl standing in a rainy neon street at night, cinematic lighting, detailed face, glossy eyes, dynamic hair, black jacket, teal accents, shallow depth of field, high detail, clean composition
```

## Negative starter

```text
low quality, blurry, worst quality, bad anatomy, extra fingers, missing fingers, deformed hands, bad hands, text, watermark, logo, jpeg artifacts
```

## Practical settings

```text
Sampler: Euler
Scheduler: simple
Steps: 8-12
CFG: 1.0-2.5
Resolution: 1024x1024 or bucket-like aspect ratios
```

For character LoRAs, put the trigger near the front and keep the rest of the
prompt descriptive instead of only tag soup.
