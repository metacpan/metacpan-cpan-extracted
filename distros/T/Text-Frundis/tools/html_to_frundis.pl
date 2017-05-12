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
# This utility script was used to translate some specific html files to the
# frundis language, but no attempt is made to make it general, and some manual
# work is needed after. That said, it can serve as a start for other works.
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

sub newlines_to_spaces {
    my $t = shift;
    $t =~ s/\n/ /g;
    return $t;
}

sub do_semantic_markup_line {
    my ($macro, $tag) = @_;
    $text =~ s|
      <$macro.*?>(.*?)</$macro>(~?[\.!\?,;:])?\s*
      |
      my $punct = $2;
      $punct = defined $punct ? " $punct" : "";
      if (defined $tag) {
          "\n.Sm -t $tag" . ' "' . newlines_to_spaces($1) . $punct . "\n"
      }
      else {
          "\n.Sm" . ' "' . newlines_to_spaces($1) . $punct . "\n"
      }
      |xseg;
}

sub do_semantic_markup_block {
    my ($macro, $tag) = @_;
    $text =~ s|
      <$macro.*?>(.*?)</$macro>(~?[\.!\?,;:])?\s*
      |
      my $punct = $2;
      $punct = defined $punct ? " $punct" : "";
      if (defined $tag) {
          "\n.Bm -t $tag\n$1\n.Em$punct\n"
      }
      else {
          "\n.Bm\n$1\n.Em$punct\n"
      }
      |xeg;
}

$text =~ s|<p>||g;
$text =~ s|</?body>||g;
$text =~ s|</table>|\n.El\n|g;
$text =~ s|</tr>||g;
$text =~ s|</dl>|\n.El\n|g;
$text =~ s|</ul>|\n.El\n|g;
$text =~ s|</?dd>||g;
$text =~ s|</li>||g;
$text =~ s|<td>||g;
$text =~ s#</p>\s*#\n.P\n#xg;
$text =~ s|<table.*?>|\n.Bl -t table -columns 3\n|sg;
$text =~ s|<ul.*?>|\n.Bl\n|sg;
$text =~ s|<dl>|\n.Bl -t desc\n|g;
$text =~ s|<tr>|\n.It\n|g;
$text =~ s|<dt>(.*?)</dt>|
    my $text = $1;
    $text =~ s/\n/ /g;
    $text = "\n.It $1\n";
    $text;
    |xesg;
$text =~ s|<li>|\n.It\n|g;
$text =~ s|<td>|\n.Ta\n|g;

$text =~ s|<h1.*?>(.*?)</h1>|\n.Pt "$1"\n|sg;
$text =~ s|<h2.*?>(.*?)</h2>|\n.Ch "$1"\n|sg;
$text =~ s|<h3.*?>(.*?)</h3>|\n.Sh "$1"\n|sg;
$text =~ s|<h4.*?>(.*?)</h4>|\n.Ss "$1"\n|sg;

$text =~ s|<a\shref="(.*?)"\s*>(.*?)</a>(~?[\.!\?,;:])?|
    my $punct = $3;
    my $href = $1;
    $href =~ s/\n/ /g;
    my $link_text = $2;
    $link_text =~ s/\n/ /g;
    $punct = defined $punct ? " $punct" : "";
    qq{\n.Lk "$href" "$link_text"$punct\n};
    |sxeg;

do_semantic_markup_block("em");
do_semantic_markup_block("strong");
do_semantic_markup_block("code");

$text =~ s/\n\s*\n+/\n/g;
$text =~ s/[ \t]*$//mg;
$text =~ s/^[ \t]*//mg;

print $text;
