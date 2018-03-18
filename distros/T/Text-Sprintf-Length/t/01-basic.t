#!perl -T

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Text::Sprintf::Length qw(sprintf_length);

is_deeply(sprintf_length("%s"), undef);
is_deeply(sprintf_length("%8s"), 8);
is_deeply(sprintf_length("%8s %% %c"), 12);

done_testing;
