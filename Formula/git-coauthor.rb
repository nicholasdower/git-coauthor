class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  license "MIT"
  version "5.1.0"
  if Hardware::CPU.arm?
    url "https://github.com/nicholasdower/git-coauthor/releases/download/v5.1.0/git-coauthor-5.1.0-aarch64-apple-darwin.tar.gz"
    sha256 "33c71c5972ed55dac1d09b0e3cb75e68120f63236011403542529f69aee4f25e"
  elsif Hardware::CPU.intel?
    url "https://github.com/nicholasdower/git-coauthor/releases/download/v5.1.0/git-coauthor-5.1.0-x86_64-apple-darwin.tar.gz"
    sha256 "03f267eca91b602cbd8830402ec094d5d75bcceec95e4646f87a522261eced94"
  end

  def install
    bin.install "bin/git-coauthor"
    man1.install "man/git-coauthor.1"
  end

  test do
    assert_match "git-coauthor", shell_output("#{bin}/git-coauthor --version")
  end
end
