package XUL::Node::Application::TextBoxExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

sub start {
	my $label;
	Window(SIZE_TO_CONTENT,
		HBox(ALIGN_CENTER,
			TextBox(Change => sub { $label->value(shift->value) }),
			$label = Label(value => '<= type text then focus out'),
		),
	);
}

1;
