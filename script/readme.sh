#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -gt 1 ]; then
  echo "usage: $0 [<bin-path>]" >&2
  exit 1
fi

if [ $# -eq 1 ]; then
  binary="$1/git-coauthor"
else
  binary="./target/debug/git-coauthor"
fi

if [ ! -f "$binary" ]; then
  echo "error: $binary does not exist" >&2
  exit 1
fi

cat << EOF > README.md
# git-coauthor

## Install

\`\`\`shell
brew install nicholasdower/tap/git-coauthor
\`\`\`

## Uninstall

\`\`\`shell
brew uninstall git-coauthor
\`\`\`

## Help

\`\`\`
$($binary -h)
\`\`\`
EOF
