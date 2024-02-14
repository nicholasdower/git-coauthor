#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <version>" >&2
  exit 1
fi

version="$1"

echo "Set version to $version"
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i "" "s/^version = .*/version = \"$version\"/g" Cargo.toml
else
  sed -i "s/^version = .*/version = \"$version\"/g" Cargo.toml
fi
