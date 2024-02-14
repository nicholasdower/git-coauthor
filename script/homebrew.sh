#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <version>" >&2
  exit 1
fi

version="$1"

function generate_sha {
  version="$1"
  name="$2"
  file="git-coauthor-$version.$name.bottle.1.tar.gz"
  if [ ! -f "$file" ]; then
    echo "error: $file not found" >&2
    exit 1
  fi
  sha=`shasum -a 256 "$file" | cut -d' ' -f1`
  echo $sha
}

release_file="git-coauthor-$version.tar.gz"
if [ ! -f "$release_file" ]; then
  echo "error: $release_file not found" >&2
  exit 1
fi

release=`shasum -a 256 "$release_file" | cut -d' ' -f1`
monterey=`generate_sha "$version" "monterey"`
ventura=`generate_sha "$version" "ventura"`
sonoma=`generate_sha "$version" "sonoma"`
arm64_sonoma=`generate_sha "$version" "arm64_sonoma"`
arm64_monterey=`generate_sha "$version" "arm64_monterey"`
arm64_ventura=`generate_sha "$version" "arm64_ventura"`

cat << EOF > Formula/git-coauthor.rb
class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  license "MIT"
  version "$version"

  url "https://github.com/nicholasdower/git-coauthor/releases/download/v$version/$release_file"
  sha256 "$release"

  bottle do
    rebuild 1
    root_url "https://github.com/nicholasdower/git-coauthor/releases/download/v$version/"
    sha256 cellar: :any, monterey: "$monterey"
    sha256 cellar: :any, ventura: "$ventura"
    sha256 cellar: :any, sonoma: "$sonoma"
    sha256 cellar: :any, arm64_sonoma: "$arm64_sonoma"
    sha256 cellar: :any, arm64_monterey: "$arm64_monterey"
    sha256 cellar: :any, arm64_ventura: "$arm64_ventura"
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
EOF
