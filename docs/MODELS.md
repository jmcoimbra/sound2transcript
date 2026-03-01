# Whisper Model Guide

Which model to use depends on your hardware and what you're transcribing. This guide covers the models that make sense for local lecture transcription on macOS.

## Recommended models

| Model | Parameters | Download size | Speed | Accuracy | Best for |
|-------|-----------|--------------|-------|----------|----------|
| `tiny` | 39M | 31 MB (q5_1) | ~10x real-time | Low | Testing your setup, quick drafts |
| `small` | 244M | 181 MB (q5_1) | ~4x real-time | Good | Fast English transcription |
| `medium` | 769M | 514 MB (q5_0) | ~2x real-time | High | Balanced quality and speed |
| **`large-v3-turbo`** | **809M** | **547 MB (q5_0)** | **~8x real-time** | **High** | **Recommended for most users** |
| `large-v3` | 1.55B | 1.1 GB (q5_0) | 1x real-time | Highest | Maximum accuracy, slow |

**Speed column**: Multiples of real-time on Apple Silicon with Metal GPU. A 60-minute recording at "~8x real-time" takes roughly 7-8 minutes to transcribe. On Intel Macs (CPU-only), divide these numbers by 3-5x.

## Why large-v3-turbo is the default

OpenAI released the turbo variant in October 2024. It reduces the decoder from 32 layers to 4 (same as the tiny model) while keeping the full large-v3 encoder. The result:

- **6-8x faster** than large-v3 with accuracy within 1-2%
- **Faster than medium** despite having more parameters (the bottleneck is decoder layers, not encoder size)
- **Smaller than medium** when quantized: 547 MB (turbo q5_0) vs 514 MB (medium q5_0) - roughly the same
- **Strong multilingual support**: English, Portuguese, and 90+ other languages
- One limitation: not trained for translation tasks. If you need to translate speech to English, use `medium` or `large-v3` instead

## Quantization

Models come in three variants:

| Variant | Size reduction | Accuracy impact | When to use |
|---------|---------------|-----------------|-------------|
| Full (no suffix) | Baseline | None | When you have disk space and want zero compromise |
| `q8_0` | ~50% smaller | Negligible | Good middle ground |
| `q5_0` / `q5_1` | ~65% smaller | Minimal (1-2%) | Recommended - best size/quality tradeoff |

For local transcription of lectures, q5_0 is the right choice. The accuracy difference is imperceptible for spoken content.

## Installation by Mac architecture

### Apple Silicon (M1, M2, M3, M4)

Apple Silicon Macs have Metal GPU which whisper.cpp uses for hardware-accelerated inference. This is the single biggest factor in transcription speed.

**Requirement**: You must use ARM-native Homebrew installed at `/opt/homebrew`. Intel Homebrew at `/usr/local` runs under Rosetta 2 emulation and produces x86_64 binaries with **no Metal GPU access**.

```bash
# Verify you're using ARM Homebrew
which brew
# Should show: /opt/homebrew/bin/brew

# If it shows /usr/local/bin/brew, install ARM Homebrew first:
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Then add to your shell profile:
# eval "$(/opt/homebrew/bin/brew shellenv)"

# Install dependencies
brew install whisper-cpp ffmpeg

# Verify native binary
file $(which whisper-cli)
# Should show: Mach-O 64-bit executable arm64
# If it shows x86_64, you're using Intel Homebrew - fix your PATH

# Download the recommended model
make download-model-turbo
```

### Intel Mac

Intel Macs run whisper.cpp on CPU only (no Metal GPU). Transcription is slower, so model choice matters more.

```bash
# Standard Homebrew install
brew install whisper-cpp ffmpeg

# For Intel, medium or small models give the best speed/quality tradeoff
make download-model          # medium (1.5 GB, ~2x real-time on CPU)
# OR for faster transcription at some accuracy cost:
# curl -L --progress-bar \
#   -o ~/sound2transcript/models/ggml-small-q5_1.bin \
#   "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.bin"
```

## Switching models

1. Download the model file (see commands above or use `make download-model-turbo`)
2. Edit `~/sound2transcript/config/config.env`:
   ```bash
   MODEL_PATH="$HOME/sound2transcript/models/ggml-large-v3-turbo-q5_0.bin"
   ```
3. Run `stream-transcribe` - the new model is used immediately

## All available models

Full list of whisper.cpp GGML models at [huggingface.co/ggerganov/whisper.cpp](https://huggingface.co/ggerganov/whisper.cpp).

Download any model with:
```bash
curl -L --progress-bar \
  -o ~/sound2transcript/models/MODEL_FILENAME \
  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/MODEL_FILENAME"
```

Replace `MODEL_FILENAME` with the exact filename from the HuggingFace repository (e.g., `ggml-small-q5_1.bin`, `ggml-large-v3-q8_0.bin`).

## Thread tuning

The `WHISPER_THREADS` config controls CPU parallelism. Set it to match your CPU core count minus a few for headroom:

| Mac | Total cores | Recommended `WHISPER_THREADS` |
|-----|------------|-------------------------------|
| M1 / M2 | 8 | 6 |
| M1 Pro / M2 Pro | 10 | 8 |
| M3 Pro | 11 | 8 |
| M1 Max / M2 Max | 10 | 8 |
| M3 Max | 14-16 | 12 |
| Intel (4-core) | 4 | 4 |
| Intel (6-core) | 6 | 5 |
| Intel (8-core) | 8 | 6 |
