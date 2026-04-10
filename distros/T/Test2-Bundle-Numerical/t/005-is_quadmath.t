use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
my $q = is_quadmath();
ok($q == 0 || $q == 1, 'is_quadmath returns a boolean value');
is($q, is_quadmath(), 'is_quadmath is stable between calls');
ok($q == 0 || $q == 1, 'is_quadmath behaves consistently as numeric boolean');
