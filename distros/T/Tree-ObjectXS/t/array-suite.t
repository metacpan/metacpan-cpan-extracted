#!perl

use 5.010001;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More 0.98;
use Test::Role::TinyCommons::Tree qw(test_role_tinycommons_tree);
use Local::TOA;
use Local::TOA1;
use Local::TOA2;

test_role_tinycommons_tree(
    class     => 'Local::TOA',
    subclass1 => 'Local::TOA1',
    subclass2 => 'Local::TOA2',

    test_nodemethods => 1,
);
done_testing;
