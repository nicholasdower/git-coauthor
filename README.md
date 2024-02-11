# git-coauthor

```
usage: git coauthor [-d] [<alias>...]

List, add or delete Git coauthors

Options

    -d, --delete    Delete coauthors
    -h, --help      Show this message
    -v, --version   Show version information

Configuration

    Create a file like:

        foo: Foo <foo@baz.com>
        bar: Bar <bar@baz.com>

    Place the file in any of the following locations:

        <home>/.gitcoauthors
        <repo>/.gitcoauthors
        <repo>/.git/coauthors

Examples

    List coauthors on the HEAD commit:

        git coauthor

    Add a coauthor to the HEAD commit:

        git coauthor foo

    Add multiple coauthors to the HEAD commit:

        git coauthor foo bar

    Delete a coauthor from the HEAD commit:

        git coauthor --delete foo

    Delete multiple coauthors from the HEAD commit:

        git coauthor --delete foo bar

    Delete all coauthors from the HEAD commit:

        git coauthor --delete

Installation

    Install:

        brew install nicholasdower/tap/git-coauthor

    Uninstall:

        brew uninstall git-coauthor
```
