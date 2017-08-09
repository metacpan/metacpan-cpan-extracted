use strict;
use warnings;
use Test::More;
use Test::Time time => 1;

is time(), 1, 'initial time taken from use line';

CORE::sleep(1);
is time(), 1, 'apparent time unchanged after changes in real time';

sleep 1;
is time(), 2, 'apparent time updated after sleep';

done_testing;
