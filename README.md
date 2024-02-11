# git-coauthor

```
usage: git coauthor [<alias>...]

List or add Git coauthors

Configuration

    Git coauthor is configured by creating a file like:

        <alias>: <name> <email>
        <alias>: <name> <email>

    The file can be placed in either or both of the following locations:

        <home>/.gitcoauthors
        <repo>/.git/coauthors

    If both files exist and contain the same alias, the alias in the repository file overrides the alias in the user file.

Examples

    Given a configuration file like:

        foo: Foo Foo <foo@foo.foo>
        bar: Bar Bar <bar@bar.bar>

    List coauthors on the HEAD commit:

        git coauthor

    Add a coauthor to the HEAD commit:

        git coauthor foo

    Add multiple coauthors to the HEAD commit:

        git coauthor foo bar

Install

    brew install nicholasdower/tap/git-coauthor

Uninstall

    brew uninstall git-coauthor
```
