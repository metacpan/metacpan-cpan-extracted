use strict;
use warnings;
use Test::More tests => 1;
use Tie::Scalar::Random;

my $line = 100;
tie $line => 'Tie::Scalar::Random', 1;
$line = 10;

my $ever_hundred = 0;

for (1..100) {
    $ever_hundred = 1 if $line == 100;
}

ok(!$ever_hundred, 'initial value is discarded');

