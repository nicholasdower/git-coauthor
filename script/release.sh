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

echo "Lint"
cargo clippy -- -Dwarnings

echo "Test"
RUNNER_TEMP=/tmp ./script/test.sh

rm -rf bin
mkdir -p bin
cp ./target/release/git-coauthor bin/

echo "Create man page"
./script/manpage.sh "$version" "$(date '+%Y-%m-%d')"

echo "Create release.tar.gz"
file="release.tar.gz"
rm -f "$file"
tar -czf "$file" ./man/ ./bin/

echo "Create Homebrew formula"
./script/homebrew.sh "$version" "$file"

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
gh release create "v$version" "$file" -R nicholasdower/git-coauthor --notes-file tmp/.release-notes

echo "Trigger Homebrew update"
gh workflow run update.yml --ref master -R nicholasdower/homebrew-tap
