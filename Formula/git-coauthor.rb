class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  license "MIT"
  if Hardware::CPU.arm?
    url "https://github.com/nicholasdower/git-coauthor/releases/download/v4.0.0/release-arm_64.tar.gz"
    sha256 "8cbb36ff11d37115e9905cc60d8cd0641a7c1f4c30f07267886e201a9fe9e6cc"
  elsif Hardware::CPU.intel?
    url "https://github.com/nicholasdower/git-coauthor/releases/download/v4.0.0/release-x86_64.tar.gz"
    sha256 "2b02c32d6731a0cf0c5e9a8c48c6009b42a795c4411b1e91813571c35799d059"
  end

  def install
    bin.install "bin/git-coauthor"
    man1.install "man/git-coauthor.1"
  end

  test do
    assert_match "git-coauthor", shell_output("#{bin}/git-coauthor --version")
  end
end
