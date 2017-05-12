#!/usr/bin/perl
# vim: set ft=perl:

use strict;
use Text::TabularDisplay;
use Test;

BEGIN {
    plan tests => 4;
}

my @data = (
    [ qw(id name phone) ],
    [ 1, "Tom Jones",     "(666) 555-1212" ],
    [ 2, "Barnaby Jones", "(666) 555-1212" ],
    [ 3, "Bridget Jones", "(666) 555-1212" ],
    [ 4, "Quincy Jones",  "(666) 555-1212" ],
);

my $t;

ok(1); # loaded...

$t = Text::TabularDisplay->new;

ok(2); # instantiated...

my @columns = @{ shift @data };
$t->columns(@columns);

ok(scalar @columns, scalar $t->columns); # columns gets/sets correctly

for (@data) {
    $t->add(@$_);
}

# How's this for an ugly test?
ok($t->render,
"+----+---------------+----------------+
| id | name          | phone          |
+----+---------------+----------------+
| 1  | Tom Jones     | (666) 555-1212 |
| 2  | Barnaby Jones | (666) 555-1212 |
| 3  | Bridget Jones | (666) 555-1212 |
| 4  | Quincy Jones  | (666) 555-1212 |
+----+---------------+----------------+");
