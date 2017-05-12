use strict;
use warnings;
use Test::More tests => 2;

use_ok 'Tie::Scalar::Random';

tie my $line => 'Tie::Scalar::Random';
like(tied($line), qr/^Tie::Scalar::Random=/);

