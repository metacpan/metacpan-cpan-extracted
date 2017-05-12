#!/usr/bin/perl
# vim: set ft=perl:

# Following a bug report from David N. Blank-Edelman <dnb@ccs.neu.edu>,
# I have added this test to check for silliness in how columns behaves.
# Regardless of how many times columns gets called, there should only be
# one element in $t->{ _COLUMNS }.

use strict;
use Text::TabularDisplay;
use Test;

BEGIN {
    plan tests => 14;
}


my $t;

$t = Text::TabularDisplay->new;
$t->columns(qw{hi there});
ok(scalar @{$t->{ _COLUMNS }}, 1);
ok(scalar $t->columns, 2);

$t->columns(qw{hi there folks});
ok(scalar @{$t->{ _COLUMNS }}, 1);
ok(scalar $t->columns, 3);

ok($t->reset);
ok($t->add(qw[1 2 3]));
ok($t->add(qw[4 5 6]));
ok($t->render, "+---+---+---+
| 1 | 2 | 3 |
| 4 | 5 | 6 |
+---+---+---+");

ok($t->columns(qw[one two three]));
ok($t->render, "+-----+-----+-------+
| one | two | three |
+-----+-----+-------+
| 1   | 2   | 3     |
| 4   | 5   | 6     |
+-----+-----+-------+");

ok($t->columns(qw[one two]));
ok($t->render, "+-----+-----+-------+
| one | two |       |
+-----+-----+-------+
| 1   | 2   | 3     |
| 4   | 5   | 6     |
+-----+-----+-------+");

ok($t->columns(qw[one two three four]));
ok($t->render, "+-----+-----+-------+------+
| one | two | three | four |
+-----+-----+-------+------+
| 1   | 2   | 3     |      |
| 4   | 5   | 6     |      |
+-----+-----+-------+------+");

