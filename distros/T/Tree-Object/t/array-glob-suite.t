#!perl

use 5.010001;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More 0.98;
use Test::Role::TinyCommons::Tree qw(test_role_tinycommons_tree);
use Local::TOAG;
use Local::TOAG1;
use Local::TOAG2;

test_role_tinycommons_tree(
    class     => 'Local::TOAG',
    subclass1 => 'Local::TOAG1',
    subclass2 => 'Local::TOAG2',

    test_nodemethods => 1,
);
done_testing;
