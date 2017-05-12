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
# This utility script was used to translate the LaTeX source code of the "El
# Ciclo de Shaedra" to the frundis language, but no attempt is made to make it
# general, and some manual work is needed after. That said, it can serve as a
# start for other works.
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
    my $macro = shift;
    $text =~ s|
      \\$macro\{([^\{\}]*)\}(~?[\.!\?,;:])?\s*
      |
      my $punct = $2;
      $punct = defined $punct ? " $punct" : "";
      "\n.Sm -t $macro" . ' "' . newlines_to_spaces($1) . '" ' . $punct . "\n"
      |xeg;
}

sub do_semantic_markup_block {
    my $macro = shift;
    $text =~ s|
        \\$macro\{([^\{\}]*)\}(~?[\.!\?,;:])\s*
        |
        my $punct = $2;
        $punct = defined $punct ? " $punct" : "";
        "\n.Bm -t $macro\n$1\n.Em$punct\n"
        |xeg;
}

# comments
$text =~ s/^%+/\.\\"/mg;
$text =~ s/(?<!\\)%+/\n\.\\"/mg;

# useless blank lines
$text =~ s/\n(?:\s*)\n/\n\n/g;

$text =~ s/\n\s*\n\s*---/\n.D\n/g;
$text =~ s/\n\s*\n\s*
        (?!(?:
            \\chapter |
            \\paragraph |
            \\begin |
            \\end |
            \\part |
            \\salto
        ))
        /\n.P\n/xg;

$text =~ s/\n\\chapter{([^\{\}]*)}/\n.Ch "$1"/g;
$text =~ s/\n\\section{([^\{\}]*)}/\n.Sh "$1"/g;
$text =~ s/\n\\subsection{([^\{\}]*)}/\n.Ss "$1"/g;
$text =~ s/\n\\part{([^\{\}]*)}/\n.Pt "$1"/g;
$text =~ s/\n\\chapter\*{([^\{\}]*)}/\n.Ch -nonum "$1"/g;
$text =~ s/\n\\section\*{([^\{\}]*)}/\n.Sh -nonum "$1"/g;
$text =~ s/\n\\subsection\*{([^\{\}]*)}/\n.Ss -nonum "$1"/g;
$text =~ s/\n\\salto *\n/\n.salto\n/g;

do_semantic_markup_line("nomlieu");
do_semantic_markup_line("emph");
do_semantic_markup_line("titulo");
do_semantic_markup_line("cancion");
do_semantic_markup_line("erare");
do_semantic_markup_block("dm");
do_semantic_markup_block("paroles");
do_semantic_markup_block("lecture");

$text =~ s/\n\s*\n+/\n/g;
$text =~ s/[ \t]*$//mg;

print $text;
