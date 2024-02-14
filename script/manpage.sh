#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <version> <date>" >&2
  exit 1
fi

version="$1"
date="$2"

rm -rf man
mkdir man
cat << EOF > man/git-coauthor.1
.TH GIT\-COAUTHOR 1 $date $version Git\ Manual
.SH NAME
\fBgit\-coauthor\fR \- List, add or delete Git coauthors
.SH SYNOPSIS
\fBgit coauthor\fR [-d] [\fIalias \.\.\.\fR]
.SH DESCRIPTION
Manage coauthors on the HEAD commit using configured aliases.
.SH OPTIONS
.TP
\fB\-d, \-\-delete\fR
Delete coauthors\.
.TP
\fB\-h, \-\-help\fR
Print help\.
.TP
\fB\-v\, \-\-version\fR
Print the version\.
.SH CONFIGURATION
Add a coauthor to the Git configuration:
.PP
.RS 4
.nf
git config --add coauthor.foo 'Foo <foo@foo.com>'
.fi
.RE
.PP
Remove a coauthor from the Git configuration:
.PP
.RS 4
.nf
git config --unset coauthor.foo
.fi
.RE
.SH EXAMPLES
List coauthors on the HEAD commit:
.PP
.RS 4
git coauthor
.RE
.PP
Add coauthors to the HEAD commit:
.PP
.RS 4
git coauthor foo bar
.RE
.PP
Delete coauthors from the HEAD commit:
.PP
.RS 4
git coauthor -d foo bar
.RE
.PP
Delete all coauthors from the HEAD commit:
.PP
.RS 4
git coauthor -d
.RE
EOF
