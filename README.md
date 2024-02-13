# git-coauthor

```
usage: git coauthor [-d] [<alias>...]

List, add or delete Git coauthors

Options

    -d, --delete    Delete coauthors.
    -h, --help      Print help.
    -v, --version   Print version.

Configuration

    Add a coauthor to the Git configuration:

        git config --add coauthor.foo 'Foo <foo@foo.com>'

    Remove a coauthor from the Git configuration:

        git config --unset coauthor.foo

Examples

    List coauthors on the HEAD commit:

        git coauthor

    Add coauthors to the HEAD commit:

        git coauthor foo bar

    Delete coauthors from the HEAD commit:

        git coauthor -d foo bar

    Delete all coauthors from the HEAD commit:

        git coauthor -d

Installation

    Install:

        brew install nicholasdower/tap/git-coauthor

    Uninstall:

        brew uninstall git-coauthor
```
