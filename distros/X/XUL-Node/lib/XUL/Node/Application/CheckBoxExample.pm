package XUL::Node::Application::CheckBoxExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

sub start {
	Window(SIZE_TO_CONTENT,
		CheckBox(
			label => 'off',
			Click => sub {
				my $checkbox = shift->source;
				$checkbox->label($checkbox->checked? 'on': 'off');
			},
		),
	);
}

1;
