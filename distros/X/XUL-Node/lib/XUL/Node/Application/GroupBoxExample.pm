package XUL::Node::Application::GroupBoxExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

sub start {
	Window(SIZE_TO_CONTENT,
		GroupBox(
			Caption(label => 'Outer GroupBox'),
			Button(label => 'Outer Button'),
			GroupBox(
				Caption(label => 'Inner GroupBox'),
				Button(label => 'Inner Button'),
			),
		),
	);
}

1;
