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
sed -i '' "s/^version = .*/version = \"$version\"/g" Cargo.toml

echo "Build"
rm -rf target
cargo build --release
cargo build --release --target x86_64-apple-darwin
cargo build --release --target aarch64-apple-darwin

echo "Lint"
cargo clippy -- -Dwarnings

echo "Test"
RUNNER_TEMP=/tmp ./script/test.sh

echo "Create man page"
./script/manpage.sh "$version" "$(date '+%Y-%m-%d')"

x86_64_file="release-x86_64.tar.gz"
arm_64_file="release-arm_64.tar.gz"

echo "Create $x86_64_file"
rm -rf bin
mkdir -p bin
cp target/x86_64-apple-darwin/release/git-coauthor bin/git-coauthor
rm -f "$x86_64_file"
tar -czf "$x86_64_file" ./man/ ./bin/


echo "Create $arm_64_file"
rm -rf bin
mkdir -p bin
cp target/aarch64-apple-darwin/release/git-coauthor bin/git-coauthor
rm -f "$arm_64_file"
tar -czf "$arm_64_file" ./man/ ./bin/

echo "Create Homebrew formula"
./script/homebrew.sh "$version"

echo "Update CHANGELOG.md"
./script/changelog.sh "$version"

echo "Update README.md"
./script/readme.sh

echo "Commit changes"
git add .
echo -e "v$version Release\n\n$(cat .release-notes)" | git commit -a -F -

echo "Add tag v$version"
git tag "v$version"

echo "Reset .release-notes"
mkdir -p tmp
cp .release-notes tmp/
echo "- No changes" > .release-notes
git add .release-notes
git commit -a -m 'Post release'

echo "Push changes"
git push origin master
git push origin "v$version"

echo "Create release"
gh release create "v$version" "$x86_64_file" "$arm_64_file" -R nicholasdower/git-coauthor --notes-file tmp/.release-notes

echo "Trigger Homebrew update"
gh workflow run update.yml --ref master -R nicholasdower/homebrew-tap
