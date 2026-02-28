# Audio Routing Setup

Required before your first recording. Takes about 3 minutes.

## What you are doing

macOS routes audio to one output at a time. To capture system audio while still hearing it, you create a Multi-Output Device that sends audio to both your speakers and BlackHole 2ch simultaneously.

BlackHole 2ch is a virtual audio loopback driver. Anything sent to it appears as an audio input that ffmpeg can capture.

## Step 1 - Install dependencies

```bash
brew install ffmpeg whisper-cpp
brew install --cask blackhole-2ch
```

You may need to approve the kernel extension in:
System Settings > Privacy & Security > (scroll down to Security section)

Restart if prompted.

## Step 2 - Verify BlackHole appears as audio device

```bash
ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep BlackHole
```

You should see a line like:

```
[AVFoundation indev] [3] BlackHole 2ch
```

The index number is resolved automatically by the script - you don't need to hardcode it.

## Step 3 - Create Multi-Output Device

1. Open **Audio MIDI Setup** (Applications > Utilities, or Spotlight search).
2. Click the **+** button in the bottom-left corner.
3. Select **Create Multi-Output Device**.
4. In the right panel, check both:
   - Your speakers (e.g., "MacBook Pro Speakers" or external speakers/headphones)
   - **BlackHole 2ch**
5. Right-click the new Multi-Output Device and select **Use This Device For Sound Output**.

Alternatively: System Settings > Sound > Output > select "Multi-Output Device".

## Step 4 - Verify audio routing

1. Play any audio in your browser.
2. Run a quick test:

```bash
ffmpeg -f avfoundation -i ":BlackHole 2ch" -t 5 -ar 16000 -ac 1 /tmp/test_capture.wav
whisper-cli -m ~/sound2transcript/models/ggml-medium.bin -f /tmp/test_capture.wav -otxt -of /tmp/test_out
cat /tmp/test_out.txt
```

The transcript should contain text matching the audio that was playing.

## Step 5 - Update your config (if needed)

Open `~/sound2transcript/config/config.env` and verify `BLACKHOLE_DEVICE_NAME="BlackHole 2ch"` matches exactly what appears in the ffmpeg device list from Step 2.

## Reverting audio routing

System Settings > Sound > Output > select your speakers directly.

The Multi-Output Device remains available for future use.

## Troubleshooting

**Transcription only outputs "you"**

Whisper processes audio in 30-second chunks. When a chunk has no real speech, it hallucinates filler tokens - "you" is the most common, others include "Thank you.", "Thanks for watching.", or just periods. The pattern is distinctive: "you" appears at exactly 30-second intervals in the SRT output:

```
1
00:00:00,000 --> 00:00:02,060
 you

2
00:00:31,000 --> 00:00:33,060
 you
```

This means BlackHole 2ch is not receiving audio. The recording pipeline works correctly, but the WAV contains silence because macOS is not routing system audio through BlackHole.

Fix: System Settings > Sound > Output > set to your Multi-Output Device (not directly to speakers or headphones). macOS resets this after reboots, software updates, or plugging/unplugging headphones.

The script includes a silence detection check (`check_audio_level`) that warns you before wasting time on transcription. To bypass it: `stream-transcribe --force`.

**No audio captured (empty transcript)**
- Confirm audio is playing while recording
- Confirm Multi-Output Device is selected as system output
- Run `ffmpeg -f avfoundation -list_devices true -i "" 2>&1` and verify BlackHole appears

**BlackHole not found after install**
- Restart macOS after installing the kernel extension
- Check System Settings > Privacy & Security for a blocked extension prompt

**Volume control lost**
- Expected with Multi-Output Device. Adjust volume through Audio MIDI Setup or control volume on the individual speaker sub-device.
