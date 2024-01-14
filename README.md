# git-coauthor

```
Manages Git coauthors.

Usage: git coauthor [option...] [alias...]

To install, add this script to your PATH, then run one of the following:

    git config --global alias.coauthor '!git-coauthor' # All repos
    git config alias.coauthor '!git-coauthor'          # Current repo only

Example Usage:
    git coauthor -h                                               # Print help

    git coauthor --config --add "foo: Foo <foo@bar.com>"          # Add a coauthor to the local config
    git coauthor --config --add --global "foo: Foo <foo@bar.com>" # Add a coauthor to the global config
    git coauthor --config --show                                  # Show the local config
    git coauthor --config --show --global                         # Show the global config
    git coauthor --config --delete                                # Delete the local config
    git coauthor --config --delete --global                       # Delete the global config
    git coauthor --config --delete foo                            # Delete one or more coauthors from the local config
    git coauthor --config --delete --global foo                   # Delete one or more coauthors from the global config

    git coauthor --prev --add alias...                            # Add one or more coauthors to the previous commit
    git coauthor --prev --show                                    # Show the coauthors on the previous commit
    git coauthor --prev --delete                                  # Delete all coauthors from the previous commit
    git coauthor --prev --delete alias...                         # Delete one or more coauthors from the previous commit

    git coauthor --template --add alias...                        # Add one or more coauthors to the Git commit template
    git coauthor --template --show                                # Show the Git commit template
    git coauthor --template --delete                              # Delete the Git commit template
    git coauthor --template --delete alias...                     # Remove one or more coauthors from the Git commit template

Options:
    -c, --config                     Update or print the coauthor configuration.
    -p, --prev                       Update or print the coauthor on the previous commit.
    -t, --template                   Update or print the Git commit template.
    -a, --add                        Add coauthors.
    -s, --show                       Show coauthors.
    -d, --delete                     Delete coauthors.
    -g, --global                     Update or print the global coauthor configuration.
```
