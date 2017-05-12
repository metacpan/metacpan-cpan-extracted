use strict;
use warnings;
use Test::More;
plan tests => 2;

use dan;
my @list = qw( foo bar baz );
is scalar(@list), 0;

no dan;
my @list2 = qw( foo bar baz );
is scalar(@list2), 3;
