#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <bin-dir> <binary>" >&2
  exit 1
fi

bin_dir="$1"
binary="$2"

binary_path="$bin_dir/$binary"

if [ ! -f "$binary_path" ]; then
  echo "error: $binary_path does not exist" >&2
  exit 1
fi

cat << EOF > README.md
# $binary

## Install

\`\`\`shell
brew install nicholasdower/tap/$binary
\`\`\`

## Uninstall

\`\`\`shell
brew uninstall $binary
\`\`\`

## Help

\`\`\`
$($binary_path -h)
\`\`\`
EOF
