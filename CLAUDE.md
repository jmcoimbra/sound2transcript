# sound2transcript

Shell-based audio transcription tool using whisper.cpp. Two scripts: `stream-transcribe` (real-time transcription) and `gc` (garbage collection for old recordings/transcripts).

## Verification Commands

```bash
# Lint (shellcheck + shfmt)
make lint

# Run bats tests
make test

# Both
make check
```

## Rules

- Never overwrite source audio files in `~/sound2transcript/recordings/`
- Never modify model files in `~/sound2transcript/models/`
- Config lives at `~/sound2transcript/config/config.env` - never commit credentials
- Shell scripts must pass `shellcheck` and `shfmt -i 2 -ci`
- Bump `VERSION` file before tagging a release

## Error Correction Log

| Date | Mistake | Correction |
|------|---------|------------|
| - | - | - |
