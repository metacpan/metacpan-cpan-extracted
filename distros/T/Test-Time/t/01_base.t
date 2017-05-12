use strict;
use warnings;
use Test::More;
use Test::Name::FromLine;
use Test::Time time => 1;

is time(), 1;

CORE::sleep(1);
is time(), 1;

sleep 1;
is time(), 2;

done_testing;
