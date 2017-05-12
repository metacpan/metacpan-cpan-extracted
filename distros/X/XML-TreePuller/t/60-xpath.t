#!/usr/bin/env perl

#there needs to be more tests, a whole
#xpath validation suite would be nice

use Test::More tests => 3;

use strict;
use warnings;

use Data::Dumper;

use XML::TreePuller;

my $root = XML::TreePuller->parse(location => 't/data/60-complicated.xml');
my @a;

ok(defined($root));

@a = $root->xpath('/complex');
ok(scalar(@a) == 1);
ok(scalar(depth($a[0])) == 0);

sub depth {
	return $_[0]->[7];
}