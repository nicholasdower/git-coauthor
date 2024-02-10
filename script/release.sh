#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 1 ]; then
  echo 'error: version required' >&2
  exit 1
fi

version=$1

sed -i '' "s/^version = .*/version = \"$version\"/g" Cargo.toml

rm -rf target
cargo build --release --all-features
RUNNER_TEMP=/tmp ./script/test.sh

rm -rf bin
mkdir -p bin
cp ./target/release/git-coauthor bin/

./script/manpage.sh "$version"

file="release.tar.gz"
rm -f "$file"
tar -czf "$file" ./man/ ./bin/

./script/homebrew.sh "$version"
./script/changelog.sh "$version"

git add .

echo -e "v$version Release\n\n$(cat .release-notes)" | git commit -a -F -

git tag "v$version"

cp .release-notes tmp/
echo "- No changes" > .release-notes
git add .release-notes
git commit -a -m 'Post release'

git push origin master
git push origin "v$version"

gh release create "v$version" "$file" -R nicholasdower/git-coauthor --notes-file tmp/.release-notes
gh workflow run update.yml --ref master -R nicholasdower/homebrew-formulas
