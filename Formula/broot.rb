class Broot < Formula
  desc "New way to see and navigate directory trees"
  homepage "https://dystroy.org/broot/"
  url "https://github.com/Canop/broot/archive/v1.6.5.tar.gz"
  sha256 "8f04e2decee489f8685263072f9f1693b0b3bf6f0d6d62161fb24e9b51a3b3ec"
  license "MIT"
  head "https://github.com/Canop/broot.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "b7170c9f5fcb26f389376c211c554cd40c62edf9cd59dffa6cb6912ae17cf3d5"
    sha256 cellar: :any_skip_relocation, big_sur:       "a79fe7d828133cbc1a5dcd1c71d9b17f9f076414c49d44d47b37134a4cfd6e9f"
    sha256 cellar: :any_skip_relocation, catalina:      "42a9448c4263d7f90a9af7361a1e465213d951e484de01d60b02d8a34f250afe"
    sha256 cellar: :any_skip_relocation, mojave:        "528d8ec1f5f02106b55b1ace95f57136be5cf8628f0194fbbe40fdb73ad8d65d"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "3512dcb063053da5ac992a5b0cace81dd0cf714612efdaa243819bb94317ae4a"
  end

  depends_on "rust" => :build

  uses_from_macos "curl" => :build
  uses_from_macos "zlib"

  def install
    system "cargo", "install", *std_cargo_args

    # Replace man page "#version" and "#date" based on logic in release.sh
    inreplace "man/page" do |s|
      s.gsub! "#version", version
      s.gsub! "#date", time.strftime("%Y/%m/%d")
    end
    man1.install "man/page" => "broot.1"

    # Completion scripts are generated in the crate's build directory,
    # which includes a fingerprint hash. Try to locate it first
    out_dir = Dir["target/release/build/broot-*/out"].first
    bash_completion.install "#{out_dir}/broot.bash"
    bash_completion.install "#{out_dir}/br.bash"
    fish_completion.install "#{out_dir}/broot.fish"
    fish_completion.install "#{out_dir}/br.fish"
    zsh_completion.install "#{out_dir}/_broot"
    zsh_completion.install "#{out_dir}/_br"
  end

  test do
    on_linux do
      return if ENV["HOMEBREW_GITHUB_ACTIONS"]
    end

    assert_match "A tree explorer and a customizable launcher", shell_output("#{bin}/broot --help 2>&1")

    require "pty"
    require "io/console"
    PTY.spawn(bin/"broot", "--cmd", ":pt", "--color", "no", "--out", testpath/"output.txt", err: :out) do |r, w, pid|
      r.winsize = [20, 80] # broot dependency termimad requires width > 2
      w.write "n\r"
      assert_match "New Configuration file written in", r.read
      Process.wait(pid)
    end
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
