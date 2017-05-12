package XUL::Node::Application::GridExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

sub start {
	Window(SIZE_TO_CONTENT,
		Grid(FLEX,
			Columns(Column(flex => 2), Column(FLEX)),
			Rows(
				Row(
					Button(label => "Rabbit"),
					Button(label => "Elephant"),
				),
				Row(
					Button(label => "Koala"),
					Button(label => "Gorilla"),
				),
			),
		),
	);
}

1;
