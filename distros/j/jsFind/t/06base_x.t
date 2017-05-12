#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1298;
use blib;
use jsFind;

BEGIN { use_ok('jsFind'); }

my @base_x = qw(
0 1 2 3 4 5 6 7 8 9
a b c d e f g h i j k l m n o p q r s t u v w x y z
);

my @nr;

diag "generating test base_x numbers";

foreach my $l (@base_x) {
	foreach my $r (@base_x) {
		if ($l eq '0') {
			push @nr, $r;
		} else {
			push @nr, $l.$r;
		}
	}
}

cmp_ok(scalar @nr, '==', 1296, "generated ".@nr." numbers");

my $i = 0;
foreach my $nr (@nr) {
	cmp_ok($nr, 'eq', jsFind::Node::base_x(undef,$i),"base_x($i) == $nr");
	$i++;
}
