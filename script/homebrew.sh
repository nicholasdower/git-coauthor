#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 3 ]; then
  echo "usage: $0 <binary> <version> <description>" >&2
  exit 1
fi

binary="$1"
version="$2"
description="$3"

class=$(echo $binary | awk -F"-" '{for (i=1; i<=NF; i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1' OFS="")

function generate_sha {
  version="$1"
  name="$2"
  file="$binary-$version.$name.bottle.1.tar.gz"
  if [ ! -f "$file" ]; then
    echo "error: $file not found" >&2
    exit 1
  fi
  sha=`shasum -a 256 "$file" | cut -d' ' -f1`
  echo $sha
}

release_file="$binary-$version.tar.gz"
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

cat << EOF > Formula/$binary.rb
class $class < Formula
  desc "$description"
  homepage "https://github.com/nicholasdower/$binary"
  license "MIT"
  version "$version"

  url "https://github.com/nicholasdower/$binary/releases/download/v$version/$release_file"
  sha256 "$release"

  bottle do
    rebuild 1
    root_url "https://github.com/nicholasdower/$binary/releases/download/v$version/"
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
    man1.install "man/$binary.1"
  end

  test do
    assert_match "$binary", shell_output("#{bin}/$binary --version")
  end
end
EOF
