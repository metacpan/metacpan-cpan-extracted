use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
use Tk;

BEGIN { use_ok('Tk::TiedListbox') };

createapp;

my $tiedlist;
if (defined $app) {
	$tiedlist = $app->TiedListbox(
	)->pack(
		-fill => 'both',
	);
}

push @tests, (
	[ sub { return defined $tiedlist }, 1, 'Axis widget created' ],
);


starttesting;
