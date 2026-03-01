<p align="center">
  <img src="logo.svg" alt="sound2transcript" width="400"/>
</p>

<p align="center">
  <a href="https://app.circleci.com/projects/circleci/M5eYL74izogsW8mjtZeouE/FLdgdyBydQqrrNBZtnev59"><img src="https://dl.circleci.com/status-badge/img/circleci/M5eYL74izogsW8mjtZeouE/FLdgdyBydQqrrNBZtnev59/tree/main.svg?style=shield" alt="CircleCI"></a>
  <a href="https://app.codacy.com/gh/jmcoimbra/sound2transcript/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade"><img src="https://app.codacy.com/project/badge/Grade/0a6d6cc43a3b4a33908317ee7db751e7" alt="Codacy Badge"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/Platform-macOS-lightgrey?logo=apple&logoColor=white" alt="Platform: macOS"></a>
</p>

# sound2transcript

Capture macOS system audio from video lectures and transcribe locally using [whisper.cpp](https://github.com/ggml-org/whisper.cpp). No cloud. No subscription. Supports English and Brazilian Portuguese via auto-detection.

## What it does

- Routes system audio through BlackHole 2ch virtual driver
- Records sessions as 16kHz mono WAV via ffmpeg
- Transcribes with whisper-cli using the medium model (1.5 GB)
- Outputs `.txt` (required), optionally `.srt` and `.vtt`
- Garbage collects old recordings on schedule via launchd

## Install

### Option A: Homebrew (recommended)

```bash
brew tap jmcoimbra/tap
brew install sound2transcript
```

This installs `stream-transcribe` and `sound2transcript-gc` into your PATH, and pulls in `ffmpeg` and `whisper-cpp` as dependencies automatically.

After installing, complete the one-time setup:

```bash
# 1. Install the virtual audio driver
brew install --cask blackhole-2ch

# 2. Download the Whisper model (1.5 GB)
curl -L --progress-bar \
  -o "$(brew --prefix)/var/sound2transcript/models/ggml-medium.bin" \
  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"

# 3. Configure audio routing (required)
open docs/SETUP.md  # or see Audio Routing below
```

### Option B: From source

```bash
git clone https://github.com/jmcoimbra/sound2transcript.git
cd sound2transcript
make install
make download-model
```

Requires [Homebrew](https://brew.sh) and macOS 13+.

## Update

### Homebrew

```bash
brew update
brew upgrade sound2transcript
```

That's it. Homebrew handles fetching the new version and replacing the binaries.

Your transcripts, recordings, model, and config are untouched - they live in the data directory, not in the Homebrew prefix.

### From source

```bash
cd sound2transcript
git pull
make install
```

Re-runs the install, copying updated scripts over the existing ones. Your data and config are preserved.

## Uninstall

### Homebrew

```bash
brew uninstall sound2transcript
brew untap jmcoimbra/tap  # optional: remove the tap
```

### From source

```bash
make uninstall
```

Both methods leave your data at `~/sound2transcript/` intact. Remove it manually if you no longer need it:

```bash
rm -rf ~/sound2transcript
```

## Audio routing

See [docs/SETUP.md](docs/SETUP.md) - required one-time setup to route system audio through BlackHole before first use.

## Use

Start recording:

```bash
stream-transcribe
```

Press **Ctrl+C** to stop. Transcription runs automatically. Output goes to `~/sound2transcript/transcripts/`.

Check version:

```bash
stream-transcribe --version
```

### Schedule garbage collection (optional)

```bash
make install-launchd
```

Runs daily at 03:30, removing old WAV files and enforcing disk caps.

## Directory layout

```
~/sound2transcript/
├── models/         # whisper model files
├── recordings/     # intermediate WAV files (auto-deleted after transcription)
├── transcripts/    # output .txt / .srt / .vtt
├── logs/           # session and gc logs
└── config/         # config.env
```

## Configuration

All settings are in `~/sound2transcript/config/config.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `BLACKHOLE_DEVICE_NAME` | `BlackHole 2ch` | Audio loopback device name |
| `MODEL_PATH` | `~/sound2transcript/models/ggml-medium.bin` | Whisper model path |
| `LANG` | `auto` | Language: `auto`, `en`, or `pt` |
| `OUTPUT_TXT` | `1` | Generate .txt output |
| `OUTPUT_SRT` | `1` | Generate .srt subtitles |
| `OUTPUT_VTT` | `0` | Generate .vtt subtitles |
| `RECORDINGS_RETENTION_DAYS` | `3` | Days to keep WAV files |
| `TRANSCRIPTS_RETENTION_DAYS` | `90` | Days to keep transcripts (0 = forever) |
| `RECORDINGS_MAX_GB` | `10` | Max disk for recordings |
| `WHISPER_THREADS` | `4` | CPU threads for transcription |

## Development

```bash
make lint       # shellcheck + shfmt
make test       # bats-core tests
make check      # lint + test
```

### Releasing a new version

1. Bump the version in `VERSION`
2. Commit: `git commit -am "Bump version to X.Y.Z"`
3. Tag and push: `make release`
4. Create the GitHub release: `gh release create vX.Y.Z`
5. Update the SHA in the [homebrew-tap](https://github.com/jmcoimbra/homebrew-tap) formula

## License

[MIT](LICENSE)
