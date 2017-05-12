#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Test::Exception;
use Test::More 0.98;
use Text::ANSITable;

subtest "add_row, add_rows, {get,set}_cell" => sub {
    my $t = Text::ANSITable->new;
    $t->add_row([11, 12, 13]);
    dies_ok { $t->add_row(21, 22, 23) } 'add_row() only accepts arrayref';
    $t->add_row([21, 22, 23]);
    $t->add_rows([[31, 32, 33], [41]]);
    dies_ok { $t->add_rows(1) } 'add_rows() only accepts arrayref';

    is(~~@{$t->rows}, 4);
    is($t->get_cell(0, 0), 11);
    is($t->get_cell(1, 2), 23);
    ok(!defined($t->get_cell(3, 1)));
    ok(!defined($t->set_cell(3, 1, 42)));
    is($t->get_cell(3, 1), 42);

    # referring column by name
    $t->columns([qw/one two three/]);
    is($t->get_cell(1, "three"), 23);
    dies_ok { $t->get_cell(1, "four") } 'unknown column name -> dies';
};

DONE_TESTING:
done_testing;
