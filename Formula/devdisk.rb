# Homebrew formula. Builds from source, so it needs no Developer ID and never meets Gatekeeper.
# Update `url` and `sha256` at each tag; `brew audit --strict --new devdisk` before submitting.
class Devdisk < Formula
  desc "Find developer build caches eating your disk, without deleting anything"
  homepage "https://github.com/1declancollier-png/devdisk"
  url "https://github.com/1declancollier-png/devdisk/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "7960a7cc867c70f9fd2c2dbaddef40bd946b35f53bdd27c42608b09710c13944"
  license "MIT"
  head "https://github.com/1declancollier-png/devdisk.git", branch: "main"

  depends_on xcode: ["15.0", :build]
  depends_on :macos

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release", "--product", "devdisk-scan"
    bin.install ".build/release/devdisk-scan" => "devdisk"
    pkgshare.install "MANIFEST.md"
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/devdisk --version").strip
    assert_match "reclaimable", shell_output(bin/"devdisk")
    # The CLI must never be able to delete. If this ever fails, something has gone very wrong.
    refute_match "--delete", shell_output("#{bin}/devdisk --help")
  end
end
