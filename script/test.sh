#!/usr/bin/env bash

if [[ -z "$RUNNER_TEMP" ]]; then
  dir="/tmp"
else
  dir="$RUNNER_TEMP"
fi

cp ./target/release/git-coauthor "$dir"
cd "$dir"
rm -rf sample-repo
mkdir -p sample-repo
mv ./git-coauthor sample-repo
cd sample-repo

function test() {
  name="$1"
  actual="$2"
  expected="$3"
  if [ "$actual" = "$expected" ]; then
    printf "\033[0;32m"
    echo "test passed: $name"
    printf "\033[0m"
  else
    printf "\033[0;31m"
    echo "test failed: $name"
    echo "expected:"
    echo "$expected"
    echo "actual:"
    echo "$actual"
    printf "\033[0m"
    exit 1
  fi
}

actual=$(./git-coauthor 2>&1)
expected=$(echo "error: failed to find repository")
test "no repository" "$actual" "$expected"

touch foo
git init --initial-branch=master --quiet
git config user.email "nicholasdower@gmail.com"
git config user.name "git-coauthor-ci"

actual=$(./git-coauthor 2>&1)
expected=$(echo "error: failed to find head")
test "no commit" "$actual" "$expected"

git add foo
git commit -m 'foo' --quiet

echo 'foo: bar' > .git/coauthors

actual=$(./git-coauthor foo 2>&1)
expected=$(echo "error: failed to read configuration")
test "invalid config" "$actual" "$expected"

echo 'foo = "Foo <foo@foo.com>"' > .git/coauthors
echo 'bar = "Bar <bar@bar.com>"' >> .git/coauthors

actual=$(./git-coauthor 2>&1)
expected=$(echo "no coauthors")
test "list no coauthors" "$actual" "$expected"

actual=$(./git-coauthor baz 2>&1)
expected=$(echo "error: coauthor not found")
test "bad coauthor" "$actual" "$expected"

actual=$(./git-coauthor foo 2>&1)
expected=$(echo "Co-authored-by: Foo <foo@foo.com>")
test "add one coauthor" "$actual" "$expected"

actual=$(./git-coauthor 2>&1)
expected=$(echo "Co-authored-by: Foo <foo@foo.com>")
test "list one coauthor" "$actual" "$expected"

actual=$(./git-coauthor bar 2>&1)
expected=$(printf "Co-authored-by: Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n")
test "add another coauthor" "$actual" "$expected"

actual=$(./git-coauthor -d foo 2>&1)
expected=$(echo "Co-authored-by: Bar <bar@bar.com>")
test "remove one coauthor" "$actual" "$expected"

git commit --amend -m 'foo' --quiet

actual=$(./git-coauthor foo bar 2>&1)
expected=$(printf "Co-authored-by: Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n")
test "add multiple coauthors" "$actual" "$expected"

actual=$(./git-coauthor 2>&1)
expected=$(printf "Co-authored-by: Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n")
test "list multiple coauthors" "$actual" "$expected"

actual=$(./git-coauthor foo 2>&1)
expected=$(printf "Co-authored-by: Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n")
test "add same coauthor" "$actual" "$expected"

actual=$(./git-coauthor 2>&1)
expected=$(printf "Co-authored-by: Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n")
test "list multiple coauthors again" "$actual" "$expected"

actual=$(./git-coauthor -d foo bar 2>&1)
expected=$(echo "no coauthors")
test "delete multiple coauthors" "$actual" "$expected"

git commit --amend -m 'foo' --quiet

echo 'foo = "Other Foo <foo@foo.com>"' > .gitcoauthors

actual=$(./git-coauthor foo bar 2>&1)
expected=$(printf "Co-authored-by: Other Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n")
test "override coauthor" "$actual" "$expected"

actual=$(./git-coauthor -d 2>&1)
expected=$(echo "no coauthors")
test "delete all coauthors" "$actual" "$expected"
