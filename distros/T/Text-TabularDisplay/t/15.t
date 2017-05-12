#!/usr/bin/perl
# vim: set ft=perl:

use strict;
use Text::TabularDisplay;
use Test;

BEGIN {
    plan tests => 1;
}

my @data = (
    [ "Joe\nShmoe", "r\ned", "9\n1/2" ],
    [ qw(foo bar baz) ],
    [ "Bob Smith", "chartreuse", "11" ],
    [ qw(foo bar baz) ],
    [ "Jumpin' Jack Flash", "yellow", "12" ],
    [ qw(foo bar baz) ],
    [ "Joe Shmoe", "red", "9 1/2" ],
    [ qw(foo bar baz) ],
    [ "Bob Smith", "chartreuse", "11" ],
    [ qw(foo bar baz) ],
    [ "Jumpin'\nJack Flash", "yellow", "12" ],
    [ "foo", "bar", "ba\nz" ],
);

my $t = Text::TabularDisplay->new("name", "favorite color", "shoe\nsize");
$t->populate([ @data ]);
ok($t->render, "+--------------------+----------------+-------+
| name               | favorite color | shoe  |
|                    |                | size  |
+--------------------+----------------+-------+
| Joe                | r              | 9     |
| Shmoe              | ed             | 1/2   |
| foo                | bar            | baz   |
| Bob Smith          | chartreuse     | 11    |
| foo                | bar            | baz   |
| Jumpin' Jack Flash | yellow         | 12    |
| foo                | bar            | baz   |
| Joe Shmoe          | red            | 9 1/2 |
| foo                | bar            | baz   |
| Bob Smith          | chartreuse     | 11    |
| foo                | bar            | baz   |
| Jumpin'            | yellow         | 12    |
| Jack Flash         |                |       |
| foo                | bar            | ba    |
|                    |                | z     |
+--------------------+----------------+-------+");
