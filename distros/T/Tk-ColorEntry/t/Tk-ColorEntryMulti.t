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
	my $row = 0;
	while ($row ne 2) {
		my $column = 0;
		while ($column ne 2) {
			$entry = $frame->ColorEntry(
				-balloon => $balloon,
				-historyfile => 't/colorentry_history',
			)->grid(
				-row => $row,
				-column => $column,
			);
			$column ++;
		}
		$row ++
	}
}

push @tests, (
	[ sub { return defined $entry }, 1, 'ColorEntry widget created' ],
);


starttesting;
