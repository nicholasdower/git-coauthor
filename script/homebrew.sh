#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 1 ]; then
  echo 'error: version required' >&2
  exit 1
fi

version=$1
url="https://github.com/nicholasdower/git-coauthor/releases/download/v$version/release.tar.gz"
sha=`shasum -a 256 "release.tar.gz" | cut -d' ' -f1`
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

  def caveats
    <<~EOS
      To add the coauthor Git alias:

        git config --global alias.coauthor '!git-coauthor'
    EOS
  end
end
EOF
