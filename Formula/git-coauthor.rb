class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  license "MIT"
  version "5.2.0"

  url "https://github.com/nicholasdower/git-coauthor/releases/download/v5.2.0/git-coauthor-5.2.0.tar.gz"
  sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

  bottle do
    rebuild 1
    root_url "https://github.com/nicholasdower/git-coauthor/releases/download/v5.2.0/"
    sha256 cellar: :any, monterey: "ffc0f92960afd03582ead5dc999f87b986465275cd73213d46f8372ce5e71aad"
    sha256 cellar: :any, ventura: "ffc0f92960afd03582ead5dc999f87b986465275cd73213d46f8372ce5e71aad"
    sha256 cellar: :any, sonoma: "ffc0f92960afd03582ead5dc999f87b986465275cd73213d46f8372ce5e71aad"
    sha256 cellar: :any, arm64_sonoma: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    sha256 cellar: :any, arm64_monterey: "ffc0f92960afd03582ead5dc999f87b986465275cd73213d46f8372ce5e71aad"
    sha256 cellar: :any, arm64_ventura: "ffc0f92960afd03582ead5dc999f87b986465275cd73213d46f8372ce5e71aad"
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
