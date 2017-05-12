#!/usr/bin/perl
# vim: set ft=perl:
# Test passing arguments to render()

use strict;
use Text::TabularDisplay;
use Test;

BEGIN {
    plan tests => 7;
}

ok(my $t = Text::TabularDisplay->new);
ok(scalar $t->columns("name", "favorite color", "shoe size"));
ok($t->add("Joe Shmoe", "red", "9 1/2"));
ok($t->add("Bob Smith", "chartreuse", "11"));
ok($t->add("John Doe", "mahogany", 13));
ok($t->render(0, 1), 
"+-----------+----------------+-----------+
| name      | favorite color | shoe size |
+-----------+----------------+-----------+
| Joe Shmoe | red            | 9 1/2     |
| Bob Smith | chartreuse     | 11        |
+-----------+----------------+-----------+");

ok($t->render(1, 2), 
"+-----------+----------------+-----------+
| name      | favorite color | shoe size |
+-----------+----------------+-----------+
| Bob Smith | chartreuse     | 11        |
| John Doe  | mahogany       | 13        |
+-----------+----------------+-----------+");
