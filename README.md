# git-coauthor

```
Adds coauthors to the previous commit.

Usage: git coauthor [option...] [alias...]

To install, add this script to your PATH, then run one of the following:

    git config --global alias.coauthor '!git-coauthor' # All repos
    git config alias.coauthor '!git-coauthor'          # Current repo only

To configure, create a .git-coauthors file in your home directory and/or at the root of your Git repo. Example:

    jerry: Jerry Seinfeld <jerry@seinfeld.com>
    george: George Costanza <george.costanza@seinfeld.com>

Example Usage:
    git coauthor -h       # Print help
    git coauthor -c       # Print configured coauthors
    git coauthor -l       # Print coauthors for the previous commit
    git coauthor -d       # Delete coauthors from the previous commit
    git coauthor alias... # Add coauthors to the previous commit

Options:
    -c, --config                     Print configured coauthors.
    -l, --list                       Print coauthors for the previous commit.
    -d, --delete                     Delete coauthors from the previous commit.
```
