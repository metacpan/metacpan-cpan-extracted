#!perl
use strict;
use warnings;
use Test::Valgrind;

use Test::More;
use Test::LeakTrace;

no_leaks_ok {
    my $a = 1 + 1;
};

done_testing;

