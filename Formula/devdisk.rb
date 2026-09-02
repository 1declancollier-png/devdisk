# Homebrew formula. Builds from source, so it needs no Developer ID and never meets Gatekeeper.
# Update `url` and `sha256` at each tag; `brew audit --strict --new devdisk` before submitting.
class Devdisk < Formula
  desc "Find developer build caches eating your disk, without deleting anything"
  homepage "https://github.com/1declancollier-png/devdisk"
  url "https://github.com/1declancollier-png/devdisk/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_AT_TAG"
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
    assert_match "devdisk #{version}", shell_output("#{bin}/devdisk --version && echo devdisk #{version}")
    assert_match "reclaimable", shell_output("#{bin}/devdisk")
  end
end
