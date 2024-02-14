class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  license "MIT"
  version "5.2.0"
  if Hardware::CPU.arm?
    url "https://github.com/nicholasdower/git-coauthor/releases/download/v5.2.0/git-coauthor-5.2.0-aarch64-apple-darwin.tar.gz"
    sha256 "05606298cdfe26f16cc52b51ab6a7fceade4f363faf77ab68656791d49c181b8"
  elsif Hardware::CPU.intel?
    url "https://github.com/nicholasdower/git-coauthor/releases/download/v5.2.0/git-coauthor-5.2.0-x86_64-apple-darwin.tar.gz"
    sha256 "d9290d9b961ae394118555adf013e80f055199f5855847e0fa40d5d294eb34cd"
  end

  def install
    bin.install "bin/git-coauthor"
    man1.install "man/git-coauthor.1"
  end

  test do
    assert_match "git-coauthor", shell_output("#{bin}/git-coauthor --version")
  end
end
