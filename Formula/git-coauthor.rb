class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  url "https://github.com/nicholasdower/git-coauthor/releases/download/v1.2.0/release.tar.gz"
  sha256 "78b2b708044bc8f078ef39aadc2df2c875e41cb5074cee6b7fcc4cc820dc40a4"
  license "MIT"

  def install
    bin.install "bin/git-coauthor"
    man1.install "man/git-coauthor.1"
  end

  test do
    assert_match "git-coauthor", shell_output("#{bin}/git-coauthor --version")
  end
end
