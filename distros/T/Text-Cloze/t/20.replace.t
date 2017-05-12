use Test::More tests => 8;
use Test::use::ok;
use strict;
use warnings;

use ok qw(Text::Cloze);

my $blank = '_' x 15;
is Text::Cloze::replace( q{Crazy}, 'blank' ), $blank, 'blank sub';
is Text::Cloze::replace( q{Floccinaucinihilipilification}, 'count' ), '(29)', 'count sub';
like Text::Cloze::replace( q{scrambled}, 'scramble' ), '/\([scrambled]{9}\)$/', 'scramble sub';
is Text::Cloze::replace( q{`Dinah'll}, 'count' ), '`(8)', 'begin punct';
is Text::Cloze::replace( q{thump!}, 'count' ), '(5)!', 'end punct';
is Text::Cloze::replace( q{thump!}, 'blank count' ), $blank.'(5)!', 'blank + count';
like Text::Cloze::replace( q{thump!}, 'blank scramble' ), "/$blank\\([thump]{5}\\)!/", 'blank + scramble';
