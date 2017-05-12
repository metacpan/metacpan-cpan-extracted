#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::NoWarnings;
use Test::More tests => 3;

BEGIN {
    use FindBin;
    use lib qq{$FindBin::Bin/lib};
}

BEGIN {
    use_ok 'Zucchini::Test';
}

can_ok(
    'Zucchini::Test',
    qw<
        add_to_tree_list
        compare_input_output
    >
);
