use strict;
use warnings;
use Test::More tests => 100;
use Tie::Scalar::Random;

tie my $line => 'Tie::Scalar::Random';
for (1..100) {
    $line = $_;
    is($line, $line);
}

