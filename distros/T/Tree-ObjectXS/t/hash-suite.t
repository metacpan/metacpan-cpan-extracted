#!perl

use 5.010001;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More 0.98;
use Test::Role::TinyCommons::Tree qw(test_role_tinycommons_tree);
use Local::TOH;
use Local::TOH1;
use Local::TOH2;

test_role_tinycommons_tree(
    class     => 'Local::TOH',
    subclass1 => 'Local::TOH1',
    subclass2 => 'Local::TOH2',

    test_nodemethods => 1,
);
done_testing;
