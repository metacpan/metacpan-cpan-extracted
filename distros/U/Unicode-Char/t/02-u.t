use strict;
use warnings;
use Test::More tests => 3;

use Unicode::Char;
my $u = Unicode::Char->new;

is($u->u5c0f, "\x{5c0f}");
is($u->u98fc, "\x{98fc}");
is($u->u5f3e, "\x{5f3e}");
