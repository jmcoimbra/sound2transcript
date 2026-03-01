class Sound2transcript < Formula
  desc "Capture macOS system audio and transcribe locally using whisper.cpp"
  homepage "https://github.com/jmcoimbra/sound2transcript"
  url "https://github.com/jmcoimbra/sound2transcript/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "2180be684cb05bd206ee646ef81f3da7e0bae935d43af2514fcb1af61fa5d31b"
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
    data_dir = Pathname.new(Dir.home) / "sound2transcript"
    %w[recordings transcripts logs models config].each do |dir|
      (data_dir / dir).mkpath
    end

    config_file = data_dir / "config" / "config.env"
    unless config_file.exist?
      cp prefix / "config" / "config.env.template", config_file
    end
  end

  def caveats
    data_dir = "~/sound2transcript"
    <<~EOS
      One-time setup required after install:

      1. Install the virtual audio driver:
           brew install --cask blackhole-2ch

      2. Download the Whisper model (1.5 GB):
           curl -L --progress-bar \\
             -o #{data_dir}/models/ggml-medium.bin \\
             "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"

      3. Configure macOS audio routing:
           See #{prefix}/docs/SETUP.md

      4. Edit your config (optional):
           #{data_dir}/config/config.env

      Data directory: #{data_dir}/
      This directory is preserved across upgrades and uninstalls.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/stream-transcribe --version")
    assert_match version.to_s, shell_output("#{bin}/sound2transcript-gc --version")
  end
end
