class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  license "MIT"
  version "6.0.0"

  url "https://github.com/nicholasdower/git-coauthor/releases/download/v6.0.0/git-coauthor-6.0.0.tar.gz"
  sha256 "f21eec8766c8d32465313374290fe40edef5b302efb8068a5ab58fdcb21a8bb6"

  bottle do
    rebuild 1
    root_url "https://github.com/nicholasdower/git-coauthor/releases/download/v6.0.0/"
    sha256 cellar: :any, monterey: "4064474bb744da3fbf282d5d77474ed67092d13c3555c9aa6b9ee78946df64b6"
    sha256 cellar: :any, ventura: "4064474bb744da3fbf282d5d77474ed67092d13c3555c9aa6b9ee78946df64b6"
    sha256 cellar: :any, sonoma: "4064474bb744da3fbf282d5d77474ed67092d13c3555c9aa6b9ee78946df64b6"
    sha256 cellar: :any, arm64_sonoma: "9e8cc06d26c0c73543c0cbca60ba85689edc4fe5402a429ade34c67becaaffb5"
    sha256 cellar: :any, arm64_monterey: "9e8cc06d26c0c73543c0cbca60ba85689edc4fe5402a429ade34c67becaaffb5"
    sha256 cellar: :any, arm64_ventura: "9e8cc06d26c0c73543c0cbca60ba85689edc4fe5402a429ade34c67becaaffb5"
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
