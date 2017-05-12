use strict;
use warnings;
use Test::More tests => 10;

use Unicode::Char;
my $u = Unicode::Char->new;

isnt($u->valid(-1),         1);
is  ($u->valid(0),          1);
is  ($u->valid(0xDBFF),     1);
isnt($u->valid(0xDC00),     1);
isnt($u->valid(0xDFFF),     1);
is  ($u->valid(0xE000),     1);
is  ($u->valid(0xFFFE),     1);
isnt($u->valid(0xFFFF),     1);
is  ($u->valid(0x10FFFF),   1);
isnt($u->valid(0xdeadbeef), 1);
