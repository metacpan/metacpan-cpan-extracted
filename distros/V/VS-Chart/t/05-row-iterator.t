#!perl

use strict;
use warnings;

use Test::More tests => 31;

use VS::Chart;
use Date::Simple;

my $chart = VS::Chart->new();

$chart->add(2);
$chart->add(4);
$chart->add(6);

my $iter = $chart->_row_iterator();

is($iter->rows, 3);
is($iter->min, 1);
is($iter->max, 3);
is($iter->next, 0);
is($iter->value, 1);
is($iter->relative, 0);
is($iter->next, 1);
is($iter->relative, 0.5);
is($iter->value, 2);
is($iter->next, 2);
is($iter->relative, 1);
is($iter->value, 3);
ok(!defined $iter->next);


$chart = VS::Chart->new();

$chart->add(Date::Simple->new("2001-01-01"));
$chart->add(Date::Simple->new("2003-01-01"));
$chart->add(Date::Simple->new("2002-01-01"));
$chart->add(Date::Simple->new("2003-06-01"));
$chart->add(Date::Simple->new("2005-01-01"));

$iter = $chart->_row_iterator();
is($iter->rows, 5);
is($iter->min, "2001-01-01");
is($iter->max, "2005-01-01");
is($iter->next, 0);
is($iter->value, "2001-01-01");
is(sprintf("%.2f", $iter->relative), "0.00");
is($iter->next, 2);
is($iter->value, "2002-01-01");
is(sprintf("%.2f", $iter->relative), "0.25");
is($iter->next, 1);
is($iter->value, "2003-01-01");
is(sprintf("%.2f", $iter->relative), "0.50");
is($iter->next, 3);
is($iter->value, "2003-06-01");
is(sprintf("%.2f", $iter->relative), "0.60");
is($iter->next, 4);
is($iter->value, "2005-01-01");
is($iter->relative, 1);
