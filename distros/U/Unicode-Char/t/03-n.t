use strict;
use warnings;
use utf8;
use Test::More tests => 5;

use Unicode::Char;
my $u = Unicode::Char->new;

is $u->latin_capital_letter_p, "P";
is $u->latin_small_letter_e,   "e";
is $u->latin_small_letter_r,   "r";
is $u->latin_small_letter_l,   "l";
is $u->dromedary_camel,        "🐪";
