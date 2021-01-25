use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok('Tie::Hash::Cannabinol');
}

my %hash : Stoned;

my @keys = qw(one two three four);

my ($k, $v, $e);

@hash{@keys} = 1 .. 4;
$k = (keys %hash)[0];
$v = $hash{$k} for 1 .. 10;
$e = exists $hash{$k};

ok(1) for 2 .. 5;

done_testing();
