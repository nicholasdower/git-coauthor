#!/usr/bin/env bash

set -e
set -u
set -o pipefail

cat << EOF > README.md
# git-coauthor

\`\`\`
$(./target/release/git-coauthor -h)
\`\`\`
EOF
