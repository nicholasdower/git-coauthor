#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <version>" >&2
  exit 1
fi

version="$1"

x86_64_file="git-coauthor-$version-x86_64.tar.gz"
arm_64_file="git-coauthor-$version-arm_64.tar.gz"

if [ ! -f "$x86_64_file" ]; then
  echo "error: $x86_64_file not found" >&2
  exit 1
fi

if [ ! -f "$arm_64_file" ]; then
  echo "error: $arm_64_file not found" >&2
  exit 1
fi

x86_64_url="https://github.com/nicholasdower/git-coauthor/releases/download/v$version/$x86_64_file"
x86_64_sha=`shasum -a 256 "$x86_64_file" | cut -d' ' -f1`

arm_64_url="https://github.com/nicholasdower/git-coauthor/releases/download/v$version/$arm_64_file"
arm_64_sha=`shasum -a 256 "$arm_64_file" | cut -d' ' -f1`

cat << EOF > Formula/git-coauthor.rb
class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  license "MIT"
  version "$version"
  if Hardware::CPU.arm?
    url "$arm_64_url"
    sha256 "$arm_64_sha"
  elsif Hardware::CPU.intel?
    url "$x86_64_url"
    sha256 "$x86_64_sha"
  end

  def install
    bin.install "bin/git-coauthor"
    man1.install "man/git-coauthor.1"
  end

  test do
    assert_match "git-coauthor", shell_output("#{bin}/git-coauthor --version")
  end
end
EOF
