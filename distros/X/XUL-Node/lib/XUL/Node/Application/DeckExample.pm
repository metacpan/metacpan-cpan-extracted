package XUL::Node::Application::DeckExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

sub start {
	local $_;
	my @colors = qw(red green blue);
	my $deck;
	Window(
		VBox(FILL,
			HBox(ALIGN_CENTER,
				MenuList(selectedIndex => 1,
					MenuPopup(map { MenuItem(label => $_, ) } @colors),
					Select => sub { $deck->selectedIndex(shift->selectedIndex) },
				),
				Label(value => '<= select a color from the deck'),
			),
			$deck = Deck(FILL, selectedIndex => 1,
				map { Box(FILL, style => "background-color: $_") } @colors,
			),
		),
	);
}

1;
