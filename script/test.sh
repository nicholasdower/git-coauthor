#!/usr/bin/env bash

if [[ -z "$RUNNER_TEMP" ]]; then
  echo "RUNNER_TEMP not set" 1>&2
  exit 1
fi

cp ./target/release/git-coauthor "$RUNNER_TEMP"
cd "$RUNNER_TEMP"
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
expected=$(echo "error: failed to get commit")
test "no commit" "$actual" "$expected"

git add foo
git commit -m 'foo' --quiet

echo "foo: Foo <foo@foo.com>" > .git/coauthors
echo "bar: Bar <bar@bar.com>" >> .git/coauthors

actual=$(./git-coauthor 2>&1)
expected=$(echo "no coauthors found")
test "list no coauthors" "$actual" "$expected"

actual=$(./git-coauthor foo 2>&1)
expected=$(echo "Co-authored-by: Foo <foo@foo.com>")
test "add one coauthor" "$actual" "$expected"

actual=$(./git-coauthor 2>&1)
expected=$(echo "Co-authored-by: Foo <foo@foo.com>")
test "list one coauthor" "$actual" "$expected"

actual=$(./git-coauthor bar 2>&1)
expected=$(printf "Co-authored-by: Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n")
test "add another coauthor" "$actual" "$expected"

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
