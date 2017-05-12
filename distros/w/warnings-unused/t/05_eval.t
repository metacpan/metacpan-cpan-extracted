#!perl -w

# to resolve RT 39563

use strict;

use warnings::unused;
use warnings;

use Test::More tests => 2;
use Test::Warn;


is(1,1, 'RT 39563');

f();

my $x;
$x++;

sub f{
	my $y; $y++;

	warning_like { eval q{
		my $z;
		sub g{
			my $zz;
			$x++;
		}
		1;
	}} [(qr/^Unused /) x 2], 'in eval';
}
