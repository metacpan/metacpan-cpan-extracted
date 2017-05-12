#!perl -w

use strict;
use Test::More tests => 4;

use WeakRef::Auto;

my @ary;
autoweaken $ary[0];

{
	my $t = [42];
	$ary[0] = $t;

	is $ary[0], $t;
}

is $ary[0], undef, 'for aelem';

my %hsh;
autoweaken $hsh{foo};
{
	my $t = [42];
	$hsh{foo} = $t;

	is $hsh{foo}, $t;
}

is $hsh{foo}, undef, 'for helem';

