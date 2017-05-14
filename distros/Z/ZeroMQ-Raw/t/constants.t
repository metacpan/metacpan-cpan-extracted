use strict;
use warnings;
use Test::More;

use ok 'ZeroMQ::Raw::Constants', qw(ZMQ_PAIR);

is(ZMQ_PAIR, 0, 'got ZMQ_PAIR (for example)');

done_testing;
