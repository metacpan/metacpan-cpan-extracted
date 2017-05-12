#!/usr/bin/env perl
# Copyright (c) 2014 Yon <anaseto@bardinflor.perso.aquilenet.fr>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

################################################################################
# This utility script was used to translate some very specific markdown files
# to the frundis language, but no attempt is made to make it general, and some
# manual work is needed after. That said, it can serve as a start for other
# works.
################################################################################

use strict;
use warnings;
use open qw(:std :utf8);
use feature 'unicode_strings';
use utf8;

my $text;
if (@ARGV) {
    my $file = shift @ARGV;
    open(my $fh, '<', $file) or die $!;
    local $/;
    $text = <$fh>;
    close $fh;
}
else {
    local $/;
    $text = <>;
}

# useless blank lines
$text =~ s/\n(?:\s*)\n/\n\n/g;
$text =~ s/\\/\\e/g;
$text =~ s/ /\\~/g;
$text =~ s/^\./\\&./mg;


# The rest
$text =~ s|^\h*\*\h*\*\h*\*.*\n+|.Bf -c -f xhtml\n<hr />\n.Ef\n|m;
$text =~ s/^(.*)\n----+\n/.Ss "$1"/gm;
$text =~ s/^(.*)\n====+\n/.Sh "$1"/gm;
$text =~ s/^##+ ?(.*)(\n\n)?/.Ss "$1"\n/gm;
$text =~ s/^# ?(.*)(\n\n)?/.Sh "$1"\n/gm;
$text =~ s/^(-.*?)\n\s*(?!-)\n/.Bl -t item\n$1\n.El\n/gsm;
$text =~ s/^-/.It\n/gm;
$text =~ s/\n\n(?=[\p{Alphabetic}])/\n.P\n/g; # XXX : check code blocks manually after!
$text =~ s/^\s*%\s*(.*)\n%\s*(.*)\n%\s*(.*)\n/
   my $t = "";
   if ($1) {
        $t = qq{.X set document-title "$1"\n};
   }
   if ($2) {
        $t .= qq{.X set document-author "$2"\n};
   }
   if ($3) {
        $t .= qq{.X set document-date "$3"\n};
   }
   $t;
/xeg;
$text =~ s|!\[(.*?)\]\((.*?)\)\n?|
    my $t = $1;
    my $l = $2;
    $t =~ s/\n+/ /g;
    qq{\n.Im "$l" "$t"\n};
|xsge;
$text =~ s|\[(.*?)\]\((.*?)\)([\.\?,;:!])?\n?|
    my $t = $1;
    my $l = $2;
    my $p = $3;
    $t =~ s/\n+/ /g;
    if ($p) {
        $t = qq{\n.Lk "$l" "$t" $p\n};
    }
    else {
        $t = qq{\n.Lk "$l" "$t"\n};
    }
    $t;
|xsge;
$text =~ s/(?<!\\)\*\*(.+?)(?<!\\)\*\*\s*([\.\?,;:!])?\n?/
    my $t = $1;
    my $p = $2;
    $t =~ s|\n+| |g;
    if ($p) {
        qq{\n.Sm -t strong "$t" $p\n}
    }
    else {
        qq{\n.Sm -t strong "$t"\n}
    }
/exgs;
$text =~ s/(?<!\\)\*(.+?)(?<!\\)\*\s*([\.\?,;:!])?\n?/
    my $t = $1;
    my $p = $2;
    $t =~ s|\n+| |g;
    if ($p) {
        qq{\n.Sm "$t" $p\n}
    }
    else {
        qq{\n.Sm "$t"\n}
    }
/exgs;
$text =~ s/(?<!\\)`(.+?)(?<!\\)`\s*([\.\?,;:!])?\n?/
    my $t = $1;
    my $p = $2;
    $t =~ s|\n+| |g;
    if ($p) {
        qq{\n.Sm -t code "$t" $p\n}
    }
    else {
        qq{\n.Sm -t code "$t"\n}
    }
/xegs;
$text =~ s/^~~~+\N*\n(.*?)\n~~~+/.Bd -t literal\n$1\n.Ed/msg;
$text =~ s/^```+\N*\n(.*?)\n```+/.Bd -t literal\n$1\n.Ed/msg;
$text =~ s/^\s*//gm;
$text =~ s/[ \t]*$//m;
# lists: manually
print $text;
