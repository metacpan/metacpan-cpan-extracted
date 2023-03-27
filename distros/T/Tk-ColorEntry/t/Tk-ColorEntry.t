use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
require Tk::Balloon;
use Tk;

BEGIN { use_ok('Tk::ColorEntry') };

createapp;

my $entry;
if (defined $app) {
	my $balloon = $app->Balloon;
	my $frame = $app->Frame(
		-width => 200,
		-height => 100,
	)->pack(-fill => 'both');
	my $l = $frame->Label(
		-width => 20,
		-height => 2,
	)->pack(
		-fill => 'both',
	);
	$entry = $frame->ColorEntry(
		-balloon => $balloon,
		-command => sub { $l->configure(-background => shift) },
		-depthselect => 1,
		-indicatorwidth => 4,
		-historyfile => 't/colorentry_history',
	)->pack(
		-fill => 'x',
	);
	$frame->Entry->pack;
}

push @tests, (
	[ sub { return defined $entry }, 1, 'ColorEntry widget created' ],
);


starttesting;
