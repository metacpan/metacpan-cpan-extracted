use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
use Tk;

BEGIN { use_ok('Tk::Dial') };

createapp;

my $dial;
if (defined $app) {
	$dial = $app->Dial(
	)->pack(
		-fill => 'both',
	);
}

push @tests, (
	[ sub { return defined $dial }, 1, 'Dial widget created' ],
);


starttesting;
