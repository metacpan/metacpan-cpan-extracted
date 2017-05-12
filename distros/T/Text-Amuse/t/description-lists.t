#!perl

use strict;
use warnings;
use Text::Amuse;
use Data::Dumper;
use File::Spec::Functions qw/catfile/;
use Test::More tests => 14;
use Text::Amuse::Document;

is (-1, Text::Amuse::Document::_compare_tolerant(0, 1), '0 < 1');
is (1, Text::Amuse::Document::_compare_tolerant(1, 0), '0 > 1');
is (0, Text::Amuse::Document::_compare_tolerant(0, 0), '0 = 1');

is (-1, Text::Amuse::Document::_compare_tolerant(1, 5), '1 < 5');
is (1, Text::Amuse::Document::_compare_tolerant(5, 1), '5 > 1');
is (0, Text::Amuse::Document::_compare_tolerant(1, 2), '1 == 2');

is (-1, Text::Amuse::Document::_compare_tolerant(2, 4), '2 < 4');
is (1, Text::Amuse::Document::_compare_tolerant(4, 2), '4 > 2');
is (0, Text::Amuse::Document::_compare_tolerant(2, 3), '2 == 3');

is (0, Text::Amuse::Document::_compare_tolerant(3, 3), '3 == 3');
is (0, Text::Amuse::Document::_compare_tolerant(2, 3), '2 == 3');
is (0, Text::Amuse::Document::_compare_tolerant(3, 2), '3 == 2');




my $doc = Text::Amuse->new(file => catfile(qw/t testfiles desc-lists.muse/));





like ($doc->as_html,
      qr!<dl>\s*<dt>term</dt>\s*<dd>\s*<p>\s*definition\s*</p>\s*</dd>.*</dl>!s,
      "HTML appears fine");
like ($doc->as_latex,
      qr!\\begin\{description\}\s*\\item\[\{term\}\]\s*definition\s.*\\end\{description\}!s,
      "LaTeX appears fine");


