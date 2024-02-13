class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  license "MIT"
  version "5.0.0"
  if Hardware::CPU.arm?
    url "https://github.com/nicholasdower/git-coauthor/releases/download/v5.0.0/git-coauthor-5.0.0-arm_64.tar.gz"
    sha256 "3d1bbe095867772229d3011b97db716c82d98312fd74f959fcb1df307718bc95"
  elsif Hardware::CPU.intel?
    url "https://github.com/nicholasdower/git-coauthor/releases/download/v5.0.0/git-coauthor-5.0.0-x86_64.tar.gz"
    sha256 "609722d7ff7f77a9861a31a2ec9c1e29facf471f973e6f7ac64d4758d3969f16"
  end

  def install
    bin.install "bin/git-coauthor"
    man1.install "man/git-coauthor.1"
  end

  test do
    assert_match "git-coauthor", shell_output("#{bin}/git-coauthor --version")
  end
end
