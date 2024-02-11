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
\fBgit\-coauthor\fR \- List or add Git coauthors
.SH SYNOPSIS
\fBgit coauthor\fR [\fIalias \.\.\.\fR]
.SH DESCRIPTION
List coauthors on the HEAD commit or add coauthors to the HEAD commit.
.SH OPTIONS
.TP
\fB\-h, \-\-help\fR
Print help\.
.TP
\fB\-v\, \-\-version\fR
Print the version\.
.SH CONFIGURATION
Create a file like:
.PP
.RS 4
.nf
foo: Foo <foo@baz.com>
bar: Bar <bar@baz.com>
.fi
.RE
.PP
Place the file in any of the following locations:
.PP
.RS 4
.nf
<home>/.gitcoauthors
<repo>/.gitcoauthors
<repo>/.git/coauthors
.fi
.RE
.SH EXAMPLES
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
.SH INSTALLATION
Install:
.PP
.RS 4
brew install nicholasdower/tap/git-coauthor
.RE
.PP
Uninstall:
.PP
.RS 4
brew uninstall git-coauthor
.RE
EOF
