class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  url "https://github.com/nicholasdower/git-coauthor/releases/download/v1.1.0/release.tar.gz"
  sha256 "cfefbb31b15582a81c10a9ebfa7cddeb33b05f179989811329e619e51cba0377"
  license "MIT"

  def install
    bin.install "bin/git-coauthor"
    man1.install "man/git-coauthor.1"
  end

  test do
    assert_match "git-coauthor", shell_output("#{bin}/git-coauthor --version")
  end
end
