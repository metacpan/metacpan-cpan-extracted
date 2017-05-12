use strict;
use warnings;

use Test::More tests => 4;                      # last test to print

use Test::Wrapper;

test_wrap( 'like' );

pass "eins";

my $x = like "foo", qw/f/;

ok ! $x->is_success, "'like' failed";

pass "zwei";

pass "drei";


