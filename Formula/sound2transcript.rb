class Sound2transcript < Formula
  desc "Capture macOS system audio and transcribe locally using whisper.cpp"
  homepage "https://github.com/jmcoimbra/sound2transcript"
  url "https://github.com/jmcoimbra/sound2transcript/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "9fb82223a4ea542b95c8e81940430306b2669b98a44606bbda1bd9a1a329f26c"
  license "MIT"
  head "https://github.com/jmcoimbra/sound2transcript.git", branch: "main"

  depends_on :macos
  depends_on "ffmpeg"
  depends_on "whisper-cpp"

  def install
    bin.install "bin/stream-transcribe"
    bin.install "bin/gc" => "sound2transcript-gc"
    prefix.install "VERSION"
    prefix.install "config"
    prefix.install "launchd"
    prefix.install "docs"
  end

  def post_install
    (var / "sound2transcript" / "recordings").mkpath
    (var / "sound2transcript" / "transcripts").mkpath
    (var / "sound2transcript" / "logs").mkpath
    (var / "sound2transcript" / "models").mkpath

    config_dir = var / "sound2transcript" / "config"
    config_dir.mkpath
    config_file = config_dir / "config.env"
    unless config_file.exist?
      cp prefix / "config" / "config.env.template", config_file
    end
  end

  def caveats
    <<~EOS
      One-time setup required after install:

      1. Install the virtual audio driver:
           brew install --cask blackhole-2ch

      2. Download the Whisper model (1.5 GB):
           curl -L --progress-bar \\
             -o #{var}/sound2transcript/models/ggml-medium.bin \\
             "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"

      3. Configure macOS audio routing:
           See #{prefix}/docs/SETUP.md

      4. Edit your config (optional):
           #{var}/sound2transcript/config/config.env

      Data directory: #{var}/sound2transcript/
      This directory is preserved across upgrades and uninstalls.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/stream-transcribe --version")
    assert_match version.to_s, shell_output("#{bin}/sound2transcript-gc --version")
  end
end
