package XUL::Node::Application::PeriodicTable::Splitters;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

sub get_demo_box {
	my $self = shift;
	VBox(FLEX,
		GroupBox(FLEX, ORIENT_HORIZONTAL,
			Caption(label => 'collapse before'),
			GroupBox(FLEX, Label(FLEX, value => 'Left side')),
			Splitter(collapse => 'before', Grippy),
			GroupBox(FLEX, Label(FLEX, value => 'Right side')),
		),
		GroupBox(FLEX, ORIENT_HORIZONTAL,
		Caption(label => 'collapse after'),
			GroupBox(FLEX, Label(FLEX, value => 'Left side')),
			Splitter(collapse => 'after', Grippy),
			GroupBox(FLEX, Label(FLEX, value => 'Right side')),
		),
		GroupBox(FLEX, ORIENT_HORIZONTAL,
		Caption(label => 'no collapse'),
			GroupBox(FLEX, Label(FLEX, value => 'Left side')),
			Splitter(collapse => 'none'),
			GroupBox(FLEX, Label(FLEX, value => 'Right side')),
		),
		GroupBox(FLEX, ORIENT_HORIZONTAL,
			Caption(label => 'resize the closest widgets on both sides'),
			GroupBox(FLEX, Description(textNode => 'Left most side')),
			GroupBox(FLEX, Description(textNode => 'Middle left side')),
			GroupBox(FLEX, Description(textNode => 'Closest left side')),
			Splitter(
				collapse     => 'none',
				resizebefore => 'closest',
				resizeafter  => 'closest',
			),
			GroupBox(FLEX, Description(textNode => 'Closest right side')),
			GroupBox(FLEX, Description(textNode => 'Middle right side')),
			GroupBox(FLEX, Description(textNode => 'Right most side')),
		),
		GroupBox(FLEX, ORIENT_HORIZONTAL,
			Caption(label => 'resize the farthest widgets on both sides'),
			GroupBox(FLEX, Description(textNode => 'Left most side')),
			GroupBox(FLEX, Description(textNode => 'Middle left side')),
			GroupBox(FLEX, Description(textNode => 'Closest left side')),
			Splitter(
				collapse     => 'none',
				resizebefore => 'farthest',
				resizeafter  => 'farthest',
			),
			GroupBox(FLEX, Description(textNode => 'Closest right side')),
			GroupBox(FLEX, Description(textNode => 'Middle right side')),
			GroupBox(FLEX, Description(textNode => 'Right most side')),
		),
		GroupBox(FLEX, ORIENT_HORIZONTAL,
			Caption(label => 'grow the widgets on the right side'),
			GroupBox(FLEX, Description(textNode => 'Left side')),
			Splitter(
				collapse     => 'none',
				resizebefore => 'grow',
				resizeafter  => 'grow',
			),
			GroupBox(FLEX, Description(textNode => 'Closest right side')),
			GroupBox(FLEX, Description(textNode => 'Middle right side')),
			GroupBox(FLEX, Description(value => 'Right most side')),
		),
		GroupBox(FLEX, ORIENT_HORIZONTAL,
			Caption(label => 'double Splitters'),
			GroupBox(FLEX, Description(textNode => 'Left side')),
			Splitter(collapse => 'before', Grippy),
			GroupBox(FLEX, Description(textNode => 'Middle')),
			Splitter(collapse => 'after', Grippy),
			GroupBox(FLEX, Description(textNode => 'Right side')),
		),
	);
}

1;
