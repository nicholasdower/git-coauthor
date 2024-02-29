class GitCoauthor < Formula
  desc "List, add or delete Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  license "MIT"
  version "6.1.1"

  url "https://github.com/nicholasdower/git-coauthor/releases/download/v6.1.1/git-coauthor-6.1.1.tar.gz"
  sha256 "457b25127f7e585044966a6e87985bf3cfaeeee2dfa1d6b7ba4e3a254bf62b89"

  bottle do
    rebuild 1
    root_url "https://github.com/nicholasdower/git-coauthor/releases/download/v6.1.1/"
    sha256 cellar: :any, monterey: "dcc4b8a2f1e05e211231ce26a55c78c07ccfe38eab52db97e04ac9727c23ef87"
    sha256 cellar: :any, ventura: "dcc4b8a2f1e05e211231ce26a55c78c07ccfe38eab52db97e04ac9727c23ef87"
    sha256 cellar: :any, sonoma: "dcc4b8a2f1e05e211231ce26a55c78c07ccfe38eab52db97e04ac9727c23ef87"
    sha256 cellar: :any, arm64_sonoma: "8cabe810804a31cc034ae350d5bb3ea0da3ebd9b80055b9ed3139944c8315386"
    sha256 cellar: :any, arm64_monterey: "8cabe810804a31cc034ae350d5bb3ea0da3ebd9b80055b9ed3139944c8315386"
    sha256 cellar: :any, arm64_ventura: "8cabe810804a31cc034ae350d5bb3ea0da3ebd9b80055b9ed3139944c8315386"
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
