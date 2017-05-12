package XUL::Node::Application::MenuListExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

sub start {
	local $_;
	my $label;
	Window(SIZE_TO_CONTENT,
		HBox(ALIGN_CENTER,
			MenuList(selectedIndex => 0,
				MenuPopup(map { MenuItem(label => "item #$_", ) } 1..10),
				Select => sub {
					$label->value
						("<= selected item #${\( shift->selectedIndex + 1 )}");
				},
			),
			$label = Label(value => '<= select item from list'),
		),
	);
}

1;
