#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  export SOUND2TRANSCRIPT_CONFIG="${TEST_DIR}/config.env"
  export HOME="$TEST_DIR"

  mkdir -p "${TEST_DIR}/sound2transcript"/{recordings,transcripts,logs,config}

  cat > "$SOUND2TRANSCRIPT_CONFIG" <<'CONF'
BLACKHOLE_DEVICE_NAME="BlackHole 2ch"
MODEL_PATH="/tmp/s2t_test_model.bin"
LANG="auto"
OUTPUT_TXT="1"
OUTPUT_SRT="0"
OUTPUT_VTT="0"
SAMPLE_RATE="16000"
CHANNELS="1"
WHISPER_THREADS="2"
RECORDINGS_RETENTION_DAYS="3"
TRANSCRIPTS_RETENTION_DAYS="90"
RECORDINGS_MAX_GB="10"
LOG_LEVEL="info"
CONF

  # Stub ffmpeg: returns device list with BlackHole at index 1
  mkdir -p "${TEST_DIR}/bin"
  cat > "${TEST_DIR}/bin/ffmpeg" <<'STUB'
#!/bin/bash
if [[ "$*" == *"list_devices"* ]]; then
  echo "[AVFoundation indev @ 0x1] [0] FaceTime HD Camera"
  echo "[AVFoundation indev @ 0x1] [0] Built-in Microphone"
  echo "[AVFoundation indev @ 0x1] [1] BlackHole 2ch"
  exit 1
fi
for arg in "$@"; do
  if [[ "$arg" == *.wav ]]; then
    printf 'RIFF____WAVEfmt ________________data____' > "$arg"
  fi
done
exit 0
STUB
  chmod +x "${TEST_DIR}/bin/ffmpeg"

  # Stub system_profiler: returns Multi-Output Device as default output
  cat > "${TEST_DIR}/bin/system_profiler" <<'STUB'
#!/bin/bash
if [[ "$1" == "SPAudioDataType" && "$2" == "-json" ]]; then
  cat <<'JSON'
{
  "SPAudioDataType": [{
    "_items": [
      {
        "_name": "MacBook Pro Speakers",
        "coreaudio_default_audio_system_device": "spaudio_yes"
      },
      {
        "_name": "Multi-Output Device",
        "coreaudio_default_audio_output_device": "spaudio_yes"
      }
    ]
  }]
}
JSON
  exit 0
fi
exit 0
STUB
  chmod +x "${TEST_DIR}/bin/system_profiler"

  # Stub whisper-cli
  cat > "${TEST_DIR}/bin/whisper-cli" <<'STUB'
#!/bin/bash
of_next=false; outfile=""
for arg in "$@"; do
  if $of_next; then outfile="$arg"; of_next=false; fi
  [[ "$arg" == "-of" ]] && of_next=true
done
[[ -n "$outfile" ]] && echo "Stub transcript" > "${outfile}.txt"
exit 0
STUB
  chmod +x "${TEST_DIR}/bin/whisper-cli"

  export PATH="${TEST_DIR}/bin:$PATH"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "--version prints version number" {
  run bin/stream-transcribe --version
  [ "$status" -eq 0 ]
  [[ "$output" == "stream-transcribe "* ]]
  [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "resolve_blackhole_index finds BlackHole 2ch at index 1" {
  source bin/stream-transcribe
  result=$(resolve_blackhole_index "BlackHole 2ch")
  [ "$result" = "1" ]
}

@test "resolve_blackhole_index returns empty for unknown device" {
  source bin/stream-transcribe
  result=$(resolve_blackhole_index "NonExistentDevice")
  [ -z "$result" ]
}

@test "fails with clear error when config missing" {
  export SOUND2TRANSCRIPT_CONFIG="/nonexistent/config.env"
  run bin/stream-transcribe
  [ "$status" -ne 0 ]
  [[ "$output" == *"config not found"* ]]
}

@test "fails when model file not found" {
  run bash -c 'source bin/stream-transcribe && validate_dependencies'
  [ "$status" -ne 0 ]
  [[ "$output" == *"model not found"* ]]
}

@test "fails when BlackHole device not in device list" {
  # Override ffmpeg stub to return no BlackHole
  cat > "${TEST_DIR}/bin/ffmpeg" <<'STUB'
#!/bin/bash
echo "[AVFoundation indev @ 0x1] [0] Built-in Microphone"
exit 1
STUB
  chmod +x "${TEST_DIR}/bin/ffmpeg"
  touch /tmp/s2t_test_model.bin

  run bin/stream-transcribe
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found in AVFoundation"* ]]

  rm -f /tmp/s2t_test_model.bin
}

@test "transcribe function rejects empty WAV file" {
  source bin/stream-transcribe
  local log_file="${TEST_DIR}/test.log"
  touch "${TEST_DIR}/empty.wav"
  run transcribe "${TEST_DIR}/empty.wav" "${TEST_DIR}/out" "$log_file"
  [ "$status" -ne 0 ]
  [[ "$output" == *"too small"* ]]
}

@test "transcribe function processes valid WAV file" {
  source bin/stream-transcribe
  local wav="${TEST_DIR}/test.wav"
  local log_file="${TEST_DIR}/test.log"

  # Create a WAV file larger than 44 bytes
  dd if=/dev/zero bs=1 count=100 of="$wav" 2>/dev/null
  touch /tmp/s2t_test_model.bin

  run transcribe "$wav" "${TEST_DIR}/out" "$log_file"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Transcription complete"* ]]
  [ ! -f "$wav" ]  # WAV should be deleted after transcription

  rm -f /tmp/s2t_test_model.bin
}

@test "check_output_device passes when Multi-Output Device is active" {
  source bin/stream-transcribe
  run check_output_device
  [ "$status" -eq 0 ]
  [[ "$output" == *"Audio output: Multi-Output Device"* ]]
}

@test "check_output_device fails when wrong device is active" {
  # Override system_profiler to return speakers as output
  cat > "${TEST_DIR}/bin/system_profiler" <<'STUB'
#!/bin/bash
cat <<'JSON'
{
  "SPAudioDataType": [{
    "_items": [
      {
        "_name": "MacBook Pro Speakers",
        "coreaudio_default_audio_output_device": "spaudio_yes"
      }
    ]
  }]
}
JSON
STUB
  chmod +x "${TEST_DIR}/bin/system_profiler"

  source bin/stream-transcribe
  run check_output_device
  [ "$status" -ne 0 ]
  [[ "$output" == *"MacBook Pro Speakers"* ]]
  [[ "$output" == *"not Multi-Output Device"* ]]
}

@test "check_output_device proceeds when detection fails" {
  # Override system_profiler to return nothing useful
  cat > "${TEST_DIR}/bin/system_profiler" <<'STUB'
#!/bin/bash
echo "{}"
STUB
  chmod +x "${TEST_DIR}/bin/system_profiler"

  source bin/stream-transcribe
  run check_output_device
  [ "$status" -eq 0 ]
  [[ "$output" == *"Could not detect"* ]]
}

@test "--force skips device check" {
  # Override system_profiler to return wrong device
  cat > "${TEST_DIR}/bin/system_profiler" <<'STUB'
#!/bin/bash
cat <<'JSON'
{
  "SPAudioDataType": [{
    "_items": [
      {
        "_name": "MacBook Pro Speakers",
        "coreaudio_default_audio_output_device": "spaudio_yes"
      }
    ]
  }]
}
JSON
STUB
  chmod +x "${TEST_DIR}/bin/system_profiler"

  touch /tmp/s2t_test_model.bin
  # --force should bypass device check; will fail at BlackHole index but not at device check
  run bin/stream-transcribe --force
  # Should NOT contain the device check error
  [[ "$output" != *"not Multi-Output Device"* ]]

  rm -f /tmp/s2t_test_model.bin
}
