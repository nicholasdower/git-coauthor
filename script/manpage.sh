#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 1 ]; then
  echo 'error: version required' >&2
  exit 1
fi

version=$1
date=$(date '+%Y-%m-%d')

rm -rf man
mkdir man
cat << EOF > man/git-coauthor.1
.TH GIT\-COAUTHOR 1 $date $version Git\ Manual
.SH NAME
\fBgit\-coauthor\fR \- List or add Git coauthors
.SH SYNOPSIS
\fBgit coauthor\fR [\fIalias \.\.\.\fR]
.SH DESCRIPTION
List coauthors on the HEAD commit or add coauthors to the HEAD commit via configured aliases.
.SH OPTIONS
.TP
\fB\-h, \-\-help\fR
Print help\.
.TP
\fB\-v\, \-\-version\fR
Print the version\.
.SH CONFIGURATION
Git coauthor is configured by creating a file like:
.PP
.RS 4
.nf
<alias>: <name> <email>
<alias>: <name> <email>
.fi
.RE
.PP
The file can be placed in either or both of the following locations:
.PP
.RS 4
.nf
<home>/.gitcoauthors
<repo>/.git/coauthors
.fi
.RE
.PP
If both files exist and contain the same alias, the alias in the repository file overrides the alias in the user file.
.SH EXAMPLES
Given a configuration file like:
.PP
.RS 4
.nf
foo: Foo Foo <foo@foo.foo>
bar: Bar Bar <bar@bar.bar>
.fi
.RE
.PP
List coauthors on the HEAD commit:
.PP
.RS 4
git coauthor
.RE
.PP
Add a coauthor to the HEAD commit:
.PP
.RS 4
git coauthor foo
.RE
.PP
Add multiple coauthors to the HEAD commit:
.PP
.RS 4
git coauthor foo bar
.RE
.SH INSTALL
To install, run:
.PP
.RS 4
.nf
brew tap nicholasdower/formulas
brew install git-coauthor
.fi
.RE
.SH UNINSTALL
To uninstall, run:
.PP
.RS 4
.nf
brew untap nicholasdower/formulas
brew uninstall git-coauthor
.fi
.RE
EOF
