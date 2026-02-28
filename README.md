<p align="center">
  <img src="logo.svg" alt="sound2transcript" width="400"/>
</p>

<p align="center">
  <a href="https://app.circleci.com/projects/circleci/M5eYL74izogsW8mjtZeouE/FLdgdyBydQqrrNBZtnev59"><img src="https://img.shields.io/circleci/build/github/jmcoimbra/sound2transcript/main?style=flat&logo=circleci&label=CI" alt="CircleCI"></a>
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

## Quick Start

### Prerequisites

- macOS 13+
- [Homebrew](https://brew.sh)

### Install

```bash
git clone https://github.com/jmcoimbra/sound2transcript.git
cd sound2transcript
make install
```

### Audio routing

See [docs/SETUP.md](docs/SETUP.md) - required one-time setup before first use.

### Download transcription model

```bash
make download-model
```

Downloads `ggml-medium.bin` (1.5 GB) to `~/sound2transcript/models/`.

### Configure

Edit `~/sound2transcript/config/config.env`. At minimum, verify `BLACKHOLE_DEVICE_NAME`.

### Use

Start recording:

```bash
stream-transcribe
```

Press **Ctrl+C** to stop. Transcription runs automatically. Output goes to `~/sound2transcript/transcripts/`.

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

## License

[MIT](LICENSE)
