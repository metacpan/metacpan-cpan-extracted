#!perl
use strict;
use utf8;
use warnings;

use Test::More;

use Text::SpeedyFx;

eval { Text::SpeedyFx->new(0) };
like($@, qr/^seed must be not 0!/, q(seed=0));

done_testing(1);
