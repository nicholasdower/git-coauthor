class GitCoauthor < Formula
  desc "List, add or delete Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  license "MIT"
  version "6.1.0"

  url "https://github.com/nicholasdower/git-coauthor/releases/download/v6.1.0/git-coauthor-6.1.0.tar.gz"
  sha256 "27f88c2047aa817b21d71e0514bdf74b663ab8a405364f4751fbbe78ad64c484"

  bottle do
    rebuild 1
    root_url "https://github.com/nicholasdower/git-coauthor/releases/download/v6.1.0/"
    sha256 cellar: :any, monterey: "595694a5fe05133cd4c5ab190f518a5187f0f0fe5fdc0c2632c486e0e1452a77"
    sha256 cellar: :any, ventura: "595694a5fe05133cd4c5ab190f518a5187f0f0fe5fdc0c2632c486e0e1452a77"
    sha256 cellar: :any, sonoma: "595694a5fe05133cd4c5ab190f518a5187f0f0fe5fdc0c2632c486e0e1452a77"
    sha256 cellar: :any, arm64_sonoma: "ccf9e086c2d82b8150d6bfbbcc04b1d0df39407bda9ff745c78522da7d94fa09"
    sha256 cellar: :any, arm64_monterey: "ccf9e086c2d82b8150d6bfbbcc04b1d0df39407bda9ff745c78522da7d94fa09"
    sha256 cellar: :any, arm64_ventura: "ccf9e086c2d82b8150d6bfbbcc04b1d0df39407bda9ff745c78522da7d94fa09"
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
