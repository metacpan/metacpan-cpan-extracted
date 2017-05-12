# generated from examples/synopsis_1.t
use strict;
use warnings;

# this test demonstrates that Test::Warnings can play nicely with
# Test::More::done_testing

use Test::More;
use Test::Warnings;

pass('yay!');
done_testing;

