use strict;
use warnings;
use Test::More tests => 1;
use Tie::Scalar::Random;

tie my $line => 'Tie::Scalar::Random', 1;
my $ever_different = 0;
for (1..100) {
    $line = $_;
    $ever_different = 1 if $line != $line;
}
ok($ever_different);

