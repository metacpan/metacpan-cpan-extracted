#!/usr/bin/perl
# vim: set ft=perl:
# Test clone method

use strict;
use Text::TabularDisplay;
use Test;

BEGIN {
    plan tests => 9;
}

ok(my $t = Text::TabularDisplay->new("name", "favorite color", "shoe size"));
ok($t->add("Joe Shmoe", "red", "9 1/2"));
ok($t->add("Bob Smith", "chartreuse", "11"));
ok($t->add("Jumpin' Jack Flash", "yellow", "12"));
ok($t->render, 
"+--------------------+----------------+-----------+
| name               | favorite color | shoe size |
+--------------------+----------------+-----------+
| Joe Shmoe          | red            | 9 1/2     |
| Bob Smith          | chartreuse     | 11        |
| Jumpin' Jack Flash | yellow         | 12        |
+--------------------+----------------+-----------+");

ok(my $u = $t->clone);
ok($u->render,  # should render the same...
"+--------------------+----------------+-----------+
| name               | favorite color | shoe size |
+--------------------+----------------+-----------+
| Joe Shmoe          | red            | 9 1/2     |
| Bob Smith          | chartreuse     | 11        |
| Jumpin' Jack Flash | yellow         | 12        |
+--------------------+----------------+-----------+");

ok($t->add("Lemony Snicket", "raw umbder", 6));

ok($u->render,  # ...even after original is modified
"+--------------------+----------------+-----------+
| name               | favorite color | shoe size |
+--------------------+----------------+-----------+
| Joe Shmoe          | red            | 9 1/2     |
| Bob Smith          | chartreuse     | 11        |
| Jumpin' Jack Flash | yellow         | 12        |
+--------------------+----------------+-----------+");
