package XUL::Node::Application::PeriodicTable::TextBoxes;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

sub get_demo_box {
	my $self = shift;
	my $label;
	VBox(
		HBox(ALIGN_CENTER,
			Label(style => 'width: 10em', value => 'Default:'),
			TextBox(Change => sub { $label->value(shift->value) }),
		),
		HBox(ALIGN_CENTER,
			Label(style => 'width: 10em', value => 'Disabled:'),
			TextBox(DISABLED,
				value    => 'disabled',
				size     => 10,
				Change   => sub { $label->value(shift->value) },
			),
		),
		HBox(ALIGN_CENTER,
			Label(style => 'width: 10em', value => 'Readonly:'),
			TextBox(readonly => 1,
				value    => 'readonly',
				size     => 30,
				Change   => sub { $label->value(shift->value) },
			),
		),
		HBox(ALIGN_CENTER,
			Label(style => 'width: 10em', value => 'Max length of 20:'),
			TextBox(maxlength => 20,
				Change => sub { $label->value(shift->value) },
			),
		),
		HBox(ALIGN_CENTER,
			Label(style => 'width: 10em', value => 'Password:'),
			TextBox
				(TYPE_PASSWORD, Change => sub { $label->value(shift->value) }),
		),
		HBox(ALIGN_CENTER,
			Label(style => 'width: 10em', value => 'Multiline:'),
			TextBox(multiline => 1, rows => 7, cols => 20,
				Change => sub { $label->value(shift->value) },
			),
		),
		HBox(ALIGN_CENTER,
			Label(style => 'width: 10em', value => 'Input:'),
			$label = Label(value => 'none yet'),
		),
	);
}

1;
