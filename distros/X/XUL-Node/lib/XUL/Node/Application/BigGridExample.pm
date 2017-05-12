package XUL::Node::Application::BigGridExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

my $ROWS = 30;
my $COLS = 20;

sub start {
	local $_;
	Window(SIZE_TO_CONTENT,
		Grid(
			Columns(map { Column } (1..$COLS)),
			Rows(
				map {
					my $row = $_;
					Row(map { Label(value => "$row:$_") } (1..$COLS))
				} (1..$ROWS),
			),
		),
	);
}

1;
