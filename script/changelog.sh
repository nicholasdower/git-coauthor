#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <version>" >&2
  exit 1
fi

version="$1"
echo "## $version" > CHANGELOG.md.new
echo >> CHANGELOG.md.new
cat .release-notes >> CHANGELOG.md.new
echo >> CHANGELOG.md.new
cat CHANGELOG.md >> CHANGELOG.md.new
mv CHANGELOG.md.new CHANGELOG.md
