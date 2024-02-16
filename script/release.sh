#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <version>" >&2
  exit 1
fi

if [ -z "${HOMEBREW_PAT}" ]; then
  echo "HOMEBREW_PAT not set" >&2
  exit 1
fi

if [ -z "${GH_TOKEN}" ]; then
  echo "GH_TOKEN not set" >&2
  exit 1
fi

version="$1"

echo "Set version to $version"
./script/version.sh "$version"

echo "Create man page"
./script/manpage.sh "$version" "$(date '+%Y-%m-%d')"

# Keep this list in sync with homebrew.sh
monterey_file="git-coauthor-$version.monterey.bottle.1.tar.gz"
ventura_file="git-coauthor-$version.ventura.bottle.1.tar.gz"
sonoma_file="git-coauthor-$version.sonoma.bottle.1.tar.gz"

arm64_monterey_file="git-coauthor-$version.arm64_monterey.bottle.1.tar.gz"
arm64_ventura_file="git-coauthor-$version.arm64_ventura.bottle.1.tar.gz"
arm64_sonoma_file="git-coauthor-$version.arm64_sonoma.bottle.1.tar.gz"

release_file="git-coauthor-$version.tar.gz"

rm -rf git-coauthor
mkdir -p "git-coauthor/$version/bin"
mkdir -p "git-coauthor/$version/share/man/man1"

echo "Create $ventura_file"
chmod +x git-coauthor-macos-13-x86_64-apple-darwin
mv git-coauthor-macos-13-x86_64-apple-darwin "git-coauthor/$version/bin/git-coauthor"
cp man/git-coauthor.1 "git-coauthor/$version/share/man/man1/"
tar -czf "$ventura_file" git-coauthor

echo "Create $arm64_sonoma_file"
chmod +x git-coauthor-macos-14-aarch64-apple-darwin
mv git-coauthor-macos-14-aarch64-apple-darwin "git-coauthor/$version/bin/git-coauthor"
tar -czf "$arm64_sonoma_file" git-coauthor

rm -rf git-coauthor

# A bit of cheating
echo "Create $arm64_monterey_file"
cp "$arm64_sonoma_file" "$arm64_monterey_file"

echo "Create $arm64_ventura_file"
cp "$arm64_sonoma_file" "$arm64_ventura_file"

echo "Create $monterey_file"
cp "$ventura_file" "$monterey_file"

echo "Create $sonoma_file"
cp "$ventura_file" "$sonoma_file"

echo "Create $release_file"
tar -czf "$release_file" ./man/ ./src/ Cargo.lock Cargo.toml

echo "Create Homebrew formula"
./script/homebrew.sh "$version"

echo "Update CHANGELOG.md"
./script/changelog.sh "$version"

echo "Update README.md"
./script/readme.sh target/release

git config user.email "nicholasdower@gmail.com"
git config user.name "git-coauthor-ci"

echo "Commit changes"
git add CHANGELOG.md
git add Cargo.lock
git add Cargo.toml
git add Formula/git-coauthor.rb
git add README.md
git add man/git-coauthor.1
echo -e "v$version Release\n\n$(cat .release-notes)" | git commit -F -

echo "Add tag v$version"
git tag "v$version"

mkdir -p tmp
cp .release-notes tmp/
echo "- No changes" > .release-notes

if ! `git diff --exit-code .release-notes > /dev/null 2>&1`; then
  echo "Reset .release-notes"
  git add .release-notes
  git commit -m 'Post release'
fi

echo "Push changes"
git push origin master
git push origin "v$version"

echo "Create release"
gh release create "v$version" \
  "$monterey_file" \
  "$ventura_file" \
  "$sonoma_file" \
  "$arm64_monterey_file" \
  "$arm64_ventura_file" \
  "$arm64_sonoma_file" \
  "$release_file" \
  -R nicholasdower/git-coauthor \
  --notes-file tmp/.release-notes

echo "Trigger Homebrew update"
GH_TOKEN=$HOMEBREW_PAT gh workflow run update.yml --ref master -R nicholasdower/homebrew-tap
