# git-coauthor

```
usage: git coauthor [<alias>...]

List or add Git coauthors

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

Installation

    Install:

        brew install nicholasdower/tap/git-coauthor

    Uninstall:

        brew uninstall git-coauthor
```
