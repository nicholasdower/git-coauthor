class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  license "MIT"
  version "5.2.1"

  url "https://github.com/nicholasdower/git-coauthor/releases/download/v5.2.1/git-coauthor-5.2.1.tar.gz"
  sha256 "186d5719267bde3c64b93dd5e7f4833074918d2669a764e0e1279aee3663df52"

  bottle do
    rebuild 1
    root_url "https://github.com/nicholasdower/git-coauthor/releases/download/v5.2.1/"
    sha256 cellar: :any, monterey: "39965896d182fa2b1ed47d32043b8012ce1dfcb9453d198c1cf6dab94c8d0610"
    sha256 cellar: :any, ventura: "39965896d182fa2b1ed47d32043b8012ce1dfcb9453d198c1cf6dab94c8d0610"
    sha256 cellar: :any, sonoma: "39965896d182fa2b1ed47d32043b8012ce1dfcb9453d198c1cf6dab94c8d0610"
    sha256 cellar: :any, arm64_sonoma: "1b6af0dd3a6cf202c7914fb8c7a35aebd8844482293d333bbe22170e6cb309cf"
    sha256 cellar: :any, arm64_monterey: "1b6af0dd3a6cf202c7914fb8c7a35aebd8844482293d333bbe22170e6cb309cf"
    sha256 cellar: :any, arm64_ventura: "1b6af0dd3a6cf202c7914fb8c7a35aebd8844482293d333bbe22170e6cb309cf"
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
