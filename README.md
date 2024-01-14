# git-coauthor

```
Manages Git coauthors.

Usage: git coauthor <args>

Installation:

    gem install git-coauthor
    git config --global alias.coauthor '!git-coauthor'
    git config --global alias.ca '!git-coauthor'

Example Usage:
    git coauthor alias...                                   # Add one or more coauthors to the previous commit
    git coauthor                                            # List the coauthors on the previous commit
    git coauthor --delete                                   # Delete all coauthors from the previous commit
    git coauthor --delete alias...                          # Delete one or more coauthors from the previous commit

    git coauthor --config "alias: Name <email>"...          # Add a coauthor to the local config
    git coauthor --config --global "alias: Name <email>"... # Add a coauthor to the global config
    git coauthor --config                                   # List the local config
    git coauthor --config --global                          # List the global config
    git coauthor --config --delete                          # Delete the local config
    git coauthor --config --delete --global                 # Delete the global config
    git coauthor --config --delete alias...                 # Delete one or more coauthors from the local config
    git coauthor --config --delete --global alias...        # Delete one or more coauthors from the global config

    git coauthor --session alias...                         # Add one or more coauthors to the current session
    git coauthor --session                                  # List the coauthors in the current session
    git coauthor --session --delete                         # Delete the current session
    git coauthor --session --delete alias...                # Delete one or more coauthors from the current session

Options:
    -d, --delete                     Delete coauthors
    -s, --session                    Updat, delete or print  session
    -c, --config                     Update, delete or print configuration
    -g, --global                     Update or print the global coauthor configuration
    -v, --version                    Print version
    -h                               Print help
```
