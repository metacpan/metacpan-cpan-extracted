#!/usr/bin/perl
# vim: set ft=perl:
# Test suggested by Patrick Kuijvenhoven <https://github.com/petski>
# in https://github.com/dlc/text--tabulardisplay/commit/4b9bd105d9ebaf8ac838e8e993216e4b56d85683#commitcomment-1540416

use strict;
use Text::TabularDisplay;
use Test;

BEGIN {
    plan tests => 1;
}

my @data = (
    ["a", "b"],
    ["", ""],
    [undef, ""],
    ["", undef],
    [undef, undef],
    [0, 0],
);

my $t = Text::TabularDisplay->new("a", "b");
$t->populate([ @data ]);
ok($t->render, "+---+---+
| a | b |
+---+---+
| a | b |
|   |   |
|   |   |
|   |   |
|   |   |
| 0 | 0 |
+---+---+");
