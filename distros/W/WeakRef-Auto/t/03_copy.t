#!perl -w

use strict;
use Test::More tests => 3;

use WeakRef::Auto;

autoweaken my $wref;

my $sref;
{
	my $t = [42];
	$wref = $t;
	$sref = $wref; # should become "strong" ref
}

is_deeply $sref, [42];
is_deeply $wref, [42];

undef $sref;

is $wref, undef;
