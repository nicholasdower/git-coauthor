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
Git coauthor manages "Co-authored-by" lines on the HEAD commit\. Coauthors may be specified as name or email details from the repository's commit history or as aliases configured via Git config\.
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
Optionally, coauthor aliases can be added to the Git config:
.PP
.RS 4
.nf
git config --add coauthor\.joe 'Joe Blow <foo@foo\.com>'
.fi
.RE
.PP
To remove a coauthor from the Git config:
.PP
.RS 4
.nf
git config --unset coauthor\.joe
.fi
.RE
.SH EXAMPLES
List coauthors on the HEAD commit:
.PP
.RS 4
.nf
git coauthor
.fi
.RE
.PP
Add coauthors to the HEAD commit:
.PP
.RS 4
.nf
git coauthor Joe
git coauthor Joe Jim
git coauthor 'Joe Blow' 'Jim Bob'
.fi
.RE
.PP
Delete coauthors from the HEAD commit:
.PP
.RS 4
.nf
git coauthor -d Joe
git coauthor -d Joe Jim
git coauthor -d 'Joe Blow' 'Jim Bob'
.fi
.RE
.PP
Delete all coauthors from the HEAD commit:
.PP
.RS 4
.nf
git coauthor -d
.fi
.RE
EOF
