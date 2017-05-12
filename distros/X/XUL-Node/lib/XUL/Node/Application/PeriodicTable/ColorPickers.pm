package XUL::Node::Application::PeriodicTable::ColorPickers;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

sub get_demo_box {
	my $self = shift;
	my $label;
	HBox(
		GroupBox(
			Caption(label => 'default colorpicker'),
			ColorPicker(Pick => sub { $label->value(shift->color) }),
			$label = Label(value => '(no input yet)'),
		),
		GroupBox(
			Caption(label => 'button type'),
			Label(value => 'Press the button'),
			Label(value => 'and doubleclick'),
			Label(value => 'to select a color'),
			ColorPicker(TYPE_BUTTON, palettename => 'standard'),
		),
	);
}

1;

