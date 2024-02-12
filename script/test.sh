#!/usr/bin/env bash

if [[ -z "$RUNNER_TEMP" ]]; then
  dir="/tmp/git-coauthor"
else
  dir="$RUNNER_TEMP/git-coauthor"
fi

rm -rf "$dir"
mkdir -p "$dir"
cp ./target/release/git-coauthor "$dir"
cd "$dir"

function test() {
  name="$1"
  if diff expected actual > /dev/null; then
    printf "\033[0;32m"
    echo "test passed: $name"
    printf "\033[0m"
  else
    printf "\033[0;31m"
    echo "test failed: $name"
    printf "\033[0m"
    diff expected actual
    exit 1
  fi
}

./git-coauthor > actual 2>&1
printf 'error: failed to find repository\n' > expected
test "no repository"

touch foo
git init --initial-branch=master --quiet
git config user.email "nicholasdower@gmail.com"
git config user.name "git-coauthor-ci"

./git-coauthor > actual 2>&1
printf 'error: failed to find head\n' > expected
test "no commit"

git add foo
git commit -m 'foo' --quiet

echo 'foo: bar' > .git/coauthors

./git-coauthor foo > actual 2>&1
printf 'error: failed to read configuration\n' > expected
test "invalid config"

echo 'foo = "Foo <foo@foo.com>"' > .git/coauthors
echo 'bar = "Bar <bar@bar.com>"' >> .git/coauthors

./git-coauthor > actual 2>&1
printf 'no coauthors\n' > expected
test "list no coauthors"

./git-coauthor baz > actual 2>&1
printf 'error: coauthor not found\n' > expected
test "bad coauthors"

./git-coauthor foo > actual 2>&1
printf 'Co-authored-by: Foo <foo@foo.com>\n' > expected
test "add one coauthor"

./git-coauthor > actual 2>&1
printf 'Co-authored-by: Foo <foo@foo.com>\n' > expected
test "list one coauthor"

./git-coauthor bar > actual 2>&1
printf 'Co-authored-by: Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n' > expected
test "list one coauthor"

./git-coauthor -d foo > actual 2>&1
printf 'Co-authored-by: Bar <bar@bar.com>\n' > expected
test "remove one coauthor"

git commit --amend -m 'foo' --quiet

./git-coauthor foo bar > actual 2>&1
printf 'Co-authored-by: Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n' > expected
test "add multiple coauthors"

./git-coauthor > actual 2>&1
printf 'Co-authored-by: Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n' > expected
test "list multiple coauthors"

./git-coauthor foo > actual 2>&1
printf 'Co-authored-by: Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n' > expected
test "add same coauthor"

./git-coauthor > actual 2>&1
printf 'Co-authored-by: Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n' > expected
test "list multiple coauthors again"

./git-coauthor -d foo bar > actual 2>&1
printf 'no coauthors\n' > expected
test "delete multiple coauthors"

git commit --amend -m 'foo' --quiet

echo 'foo = "Other Foo <foo@foo.com>"' > .gitcoauthors

./git-coauthor foo bar > actual 2>&1
printf 'Co-authored-by: Other Foo <foo@foo.com>\nCo-authored-by: Bar <bar@bar.com>\n' > expected
test "override coauthor"

./git-coauthor -d > actual 2>&1
printf 'no coauthors\n' > expected
test "delete all coauthors"
