#!perl

use 5.010001;
use strict;
use warnings;

use Test::More;
use Test::Needs;
use Text::ANSITable;

subtest "set_cell_style(format)" => sub {
    test_needs "Data::Unixish::Apply";

    my $t = Text::ANSITable->new;
    $t->columns(["col"]);
    $t->add_row(['x']);
    $t->add_row([0]);
    $t->set_cell_style(0, 0, formats => ['uc']);
    $t->set_cell_style(1, 0, formats => [[bool => {style=>'t_f'}]]);

    my $t_str = $t->draw;

    note $t_str;
    like($t_str, qr/\bX\b/) or diag $t_str;
    like($t_str, qr/\bf\b/) or diag $t_str;
};

done_testing;
