#!perl

use strict;
use Test::More tests => 1;
BEGIN{ $SIG{__WARN__} = \&fail }
END{ pass 'done.' }

use Errno (); # preload for Devel::Cover

use warnings::unused;
use warnings;

my $var; $var++;

{
	my $foo;

	sub foo{
		my $bar;
		$bar->($foo);
	}

	sub bar{
		my $x;
		print "$x";
	}

	sub baz{
		my $y;
		s/foo/$y/;
	}
}

eval{
	my $x;
	$x++;
};
