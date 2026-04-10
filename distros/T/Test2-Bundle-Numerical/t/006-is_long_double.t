use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
my $q = is_long_double();
ok($q == 0 || $q == 1, 'is_long_double returns a boolean value');
is($q, is_long_double(), 'is_long_double is stable between calls');
ok($q == 0 || $q == 1, 'is_long_double behaves consistently as numeric boolean');
