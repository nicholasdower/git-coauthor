#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <version> <file>" >&2
  exit 1
fi

version="$1"
file="$2"

url="https://github.com/nicholasdower/git-coauthor/releases/download/v$version/$file"
sha=`shasum -a 256 "$file" | cut -d' ' -f1`
cat << EOF > Formula/git-coauthor.rb
class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  url "$url"
  sha256 "$sha"
  license "MIT"

  def install
    bin.install "bin/git-coauthor"
    man1.install "man/git-coauthor.1"
  end

  test do
    assert_match "git-coauthor", shell_output("#{bin}/git-coauthor --version")
  end
end
EOF
