use strict;
use warnings;
use charnames ":full";
use Test::More tests => 3;
use Text::Bidi qw(is_bidi);

ok is_bidi("\N{HEBREW LETTER AYIN}"), "hebrew is bidi";
ok is_bidi("\N{ARABIC LETTER AIN}"), "arabic is bidi";
ok ! is_bidi("A"), "latin is not bidi";
