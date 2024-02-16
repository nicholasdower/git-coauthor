class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  license "MIT"
  version "5.2.2"

  url "https://github.com/nicholasdower/git-coauthor/releases/download/v5.2.2/git-coauthor-5.2.2.tar.gz"
  sha256 "2dae2349f92a73b2d5f038e8cceecb1299e75d78980160009757b3eb3f6593fe"

  bottle do
    rebuild 1
    root_url "https://github.com/nicholasdower/git-coauthor/releases/download/v5.2.2/"
    sha256 cellar: :any, monterey: "335805936cd83abd879a10dc3152e39c7c53856c5d82424e7adc44fef64cb3ab"
    sha256 cellar: :any, ventura: "335805936cd83abd879a10dc3152e39c7c53856c5d82424e7adc44fef64cb3ab"
    sha256 cellar: :any, sonoma: "335805936cd83abd879a10dc3152e39c7c53856c5d82424e7adc44fef64cb3ab"
    sha256 cellar: :any, arm64_sonoma: "cabe33d5525c47596f45804f5517f277454cbecdd46bd942f22bcfa944221541"
    sha256 cellar: :any, arm64_monterey: "cabe33d5525c47596f45804f5517f277454cbecdd46bd942f22bcfa944221541"
    sha256 cellar: :any, arm64_ventura: "cabe33d5525c47596f45804f5517f277454cbecdd46bd942f22bcfa944221541"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-coauthor.1"
  end

  test do
    assert_match "git-coauthor", shell_output("#{bin}/git-coauthor --version")
  end
end
