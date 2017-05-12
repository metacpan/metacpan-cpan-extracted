#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan tests => 324;

use Time::C;
use Time::F;
use Time::P;

my @ts;

for my $year (1990 .. 2016) {
    push @ts,
      Time::C->new($year),
      Time::C->new($year, 1, 22),
      Time::C->new($year, 12, 31),
      ;
}

my $fmt = "%G: %V-%w";
foreach my $t (@ts) {
    my $str = strftime $t, $fmt;
    my $str2 = $t->tm->strftime($fmt);

    is ($str, $str2, "Week for $t formatted correctly.") or BAIL_OUT;
}

$fmt = "%Y: %W-%w";
foreach my $t (@ts) {
    my $str = strftime $t, $fmt;
    my $str2 = $t->tm->strftime($fmt);

    is ($str, $str2, "Week for $t formatted correctly.") or BAIL_OUT;
}

$fmt = "%G: %V-%w";
foreach my $t (@ts) {
    my $str = strftime $t, $fmt;
    my $t2 = Time::C->strptime($str, $fmt);

    is ($t2, $t, "Week for $t parsed correctly.") or diag "$t => ($fmt) => $str => $t2";
}

$fmt = "%Y: %W-%w";
foreach my $t (@ts) {
    my $str = strftime $t, $fmt;
    my $t2 = Time::C->strptime($str, $fmt);

    is ($t2, $t, "Week for $t parsed correctly.") or diag "$t => ($fmt) => $str => $t2";
}

#done_testing;
