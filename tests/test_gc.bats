#!/usr/bin/env bats

# Portable date helper: works on macOS (date -v) and Linux (date -d)
backdate() {
  local file="$1"
  local days="$2"
  local ts
  if date -v-1d +%Y%m%d%H%M >/dev/null 2>&1; then
    ts=$(date -v-"${days}"d +%Y%m%d%H%M)
  else
    ts=$(date -d "${days} days ago" +%Y%m%d%H%M)
  fi
  touch -t "$ts" "$file"
}

setup() {
  TEST_DIR="$(mktemp -d)"
  export SOUND2TRANSCRIPT_CONFIG="${TEST_DIR}/config.env"
  export HOME="$TEST_DIR"

  mkdir -p "${TEST_DIR}/sound2transcript"/{recordings,transcripts,logs}

  cat > "$SOUND2TRANSCRIPT_CONFIG" <<'CONF'
RECORDINGS_RETENTION_DAYS="3"
TRANSCRIPTS_RETENTION_DAYS="30"
RECORDINGS_MAX_GB="1"
LOG_LEVEL="info"
CONF
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "--version prints version number" {
  run bin/gc --version
  [ "$status" -eq 0 ]
  [[ "$output" == "sound2transcript-gc "* ]]
  [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "gc runs without error on empty directories" {
  run bin/gc
  [ "$status" -eq 0 ]
  [[ "$output" == *"GC complete"* ]]
}

@test "gc removes WAV files older than retention days" {
  local wav="${TEST_DIR}/sound2transcript/recordings/old_session.wav"
  touch "$wav"
  backdate "$wav" 10

  run bin/gc
  [ "$status" -eq 0 ]
  [ ! -f "$wav" ]
}

@test "gc retains WAV files within retention days" {
  local wav="${TEST_DIR}/sound2transcript/recordings/recent.wav"
  touch "$wav"

  run bin/gc
  [ "$status" -eq 0 ]
  [ -f "$wav" ]
}

@test "gc removes old transcripts when retention > 0" {
  local txt="${TEST_DIR}/sound2transcript/transcripts/old.txt"
  touch "$txt"
  backdate "$txt" 40

  run bin/gc
  [ "$status" -eq 0 ]
  [ ! -f "$txt" ]
}

@test "gc skips transcript deletion when retention is 0" {
  cat > "$SOUND2TRANSCRIPT_CONFIG" <<'CONF'
RECORDINGS_RETENTION_DAYS="3"
TRANSCRIPTS_RETENTION_DAYS="0"
RECORDINGS_MAX_GB="1"
LOG_LEVEL="info"
CONF

  local txt="${TEST_DIR}/sound2transcript/transcripts/keep.txt"
  touch "$txt"
  backdate "$txt" 100

  run bin/gc
  [ "$status" -eq 0 ]
  [ -f "$txt" ]
  [[ "$output" == *"unlimited"* ]]
}

@test "gc creates dated log file" {
  run bin/gc
  [ "$status" -eq 0 ]
  local log_file="${TEST_DIR}/sound2transcript/logs/gc_$(date +%Y%m%d).log"
  [ -f "$log_file" ]
}
