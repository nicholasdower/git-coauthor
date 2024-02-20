# git-coauthor

## Install

```shell
brew install nicholasdower/tap/git-coauthor
```

## Uninstall

```shell
brew uninstall git-coauthor
```

## Help

```
usage: git coauthor [-d] [<alias>...]

List, add or delete Git coauthors

Description

    Git coauthor manages "Co-authored-by" lines on the HEAD commit. Coauthors
    are specified as name or email details from the repository's commit history
    or as aliases configured via `git config`.

Options

    -d, --delete    Delete coauthors.
    -h, --help      Print help.
    -v, --version   Print version.

Configuration

    Optionally, coauthor aliases can be added to the Git config:

        git config --add coauthor.joe 'Joe Blow <foo@foo.com>'

    To remove a coauthor from the Git config:

        git config --unset coauthor.joe

Examples

    List coauthors on the HEAD commit:

        git coauthor

    Add coauthors to the HEAD commit:

        git coauthor Joe
        git coauthor Joe Jim
        git coauthor "Joe Blow" "Jim Bob"

    Delete coauthors from the HEAD commit:

        git coauthor -d Joe
        git coauthor -d Joe Jim
        git coauthor -d "Joe Blow" "Jim Bob"

    Delete all coauthors from the HEAD commit:

        git coauthor -d
```
