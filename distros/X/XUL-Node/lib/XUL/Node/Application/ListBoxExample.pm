package XUL::Node::Application::ListBoxExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

sub start {
	local $_;
	my $label;
	Window(
		VBox(FILL,
			$label = Label(value => 'select item from list'),
			ListBox(FILL, selectedIndex => 2,
				(map { ListItem(label => "item #$_") } 1..10),
				Select => sub {
					$label->value
						("selected item #${\( shift->selectedIndex + 1 )}");
				},
			),
		),
	);
}

1;
