#!perl
# ex:ts=4:sw=4:sts=4:et

use strict;
use lib qw(lib);
use Transmission::Utils ();
use Test::More;

plan tests => 8;

my $numeric = 16;
my $str = "stopped";

ok(!*from_numeric_status{'CODE'}, "from_numeric_status not imported");
ok(!*to_numeric_status{'CODE'}, "to_numeric_status not imported");

Transmission::Utils->import('from_numeric_status');
ok(*from_numeric_status{'CODE'}, "from_numeric_status imported");
is(from_numeric_status($numeric), $str, "from_numeric_status ok");
is(from_numeric_status(-1), "", "from_numeric_status ok");

Transmission::Utils->import('to_numeric_status');
ok(*to_numeric_status{'CODE'}, "to_numeric_status imported");
is(to_numeric_status($str), $numeric, "to_numeric_status ok");
is(to_numeric_status("foo"), -1, "to_numeric_status ok");

