use strict;
use warnings;
use Test::More tests => 4;

use Unicode::Char;
my $u = Unicode::Char->new;

is $u->u5c0f,  "\x{5c0f}";
is $u->u98fc,  "\x{98fc}";
is $u->u5f3e,  "\x{5f3e}";
is $u->u1f42a, "\x{1f42a}";
