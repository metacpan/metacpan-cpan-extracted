package XUL::Node::Application::SplitterExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

sub start {
	Window(
		VBox(FILL,
			HBox(FILL,
				Box(FILL, style => 'background-color: red'),
				Splitter,
				Box(FILL, style => 'background-color: blue'),
			),
			Splitter,
			Box(FILL, style => 'background-color: green'),
		),
	);
}

1;
