use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
use Tk;

BEGIN { use_ok('Tk::Axis') };

createapp;

my $axis;
if (defined $app) {
	$axis = $app->Axis(
	)->pack(
		-fill => 'both',
	);
}

push @tests, (
	[ sub { return defined $axis }, 1, 'Axis widget created' ],
);


starttesting;
