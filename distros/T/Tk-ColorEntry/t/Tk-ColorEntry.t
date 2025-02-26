use strict;
use warnings;
use Test::More tests => 5;
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
		-command => sub { $l->configure(-background => $entry->getHEX) },
		-depthselect => 1,
		-indicatorwidth => 4,
		-historyfile => 't/colorentry_history',
		-notationselect => 1,
	)->pack(
		-fill => 'x',
	);
	$frame->Entry->pack;
}

push @tests, (
	[ sub { return defined $entry }, 1, 'ColorEntry widget created' ],
	[ sub {
		$entry->put('#477F47');
		return $entry->get 
	}, '#477F47', 'Putting color' ],
	
);


starttesting;
