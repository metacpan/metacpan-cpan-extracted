package XUL::Node::Application::PeriodicTable::CheckBoxes;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

sub get_demo_box {
	my $self = shift;
	my $labels = {};
	VBox(FILL,
		HBox(
			GroupBox(FLEX,
				Caption(label => 'tabbing'),
				VBox(FLEX,
					Label(value => 'These tab oddly.'),
					CheckBox(FLEX, label => '6', tabindex => 6,
						Click => sub { $labels->{tab}->value(6) },
					),
					CheckBox(FLEX, label => '3', tabindex => 3,
						Click => sub { $labels->{tab}->value(3) },
					),
					CheckBox(FLEX, label => '4', tabindex => 4,
						Click => sub { $labels->{tab}->value(4) },
					),
					CheckBox(FLEX, label => '2', tabindex => 2,
						Click => sub { $labels->{tab}->value(2) },
					),
					CheckBox(FLEX, label => '5', tabindex => 5,
						Click => sub { $labels->{tab}->value(5) },
					),
					CheckBox(FLEX, label => '1', tabindex => 1,
						Click => sub { $labels->{tab}->value(1) },
					),
					Seperator(FLEX),
					$labels->{tab} = Label(value => '(no input yet)'),
				),
			),
			GroupBox(FLEX,
				Caption(label => 'accesskeys'),
				VBox(FLEX,
					Label(value => 'These have access keys.'),
					Label(value => q{(Even if they're not marked)}),
					CheckBox(FLEX, label => 'Animal', accesskey => 'a',
						Click => sub { $labels->{accesskey}->value('Animal') },
					),
					CheckBox(FLEX, label => 'Bear', accesskey => 'b',
						Click => sub { $labels->{accesskey}->value('Bear') },
					),
					CheckBox(FLEX, label => 'Cat', accesskey => 'c',
						Click => sub { $labels->{accesskey}->value('Cat') },
					),
					CheckBox(FLEX, label => 'Dog', accesskey => 'd',
						Click => sub { $labels->{accesskey}->value('Dog') },
					),
					CheckBox(FLEX, label => 'Deer', accesskey => 'e',
						Click => sub { $labels->{accesskey}->value('Deer') },
					),
					CheckBox(FLEX, label => 'Fish', accesskey => 'f',
						Click => sub { $labels->{accesskey}->value('Fish') },
					),
					Seperator(FLEX),
					$labels->{accesskey} = Label(value => '(no input yet)'),
				),
			),
			GroupBox(FLEX,
				Caption(label => 'states'),
				VBox(FLEX,
					Label(value => 'These show different states.'),
					CheckBox(FLEX, label => 'Default', default => 1,
						Click => sub { $labels->{state}->value('Default') },
					),
					CheckBox(FLEX, label => 'Checked', checked => 1,
						Click => sub { $labels->{state}->value('Checked') },
					),
					CheckBox(FLEX, label => 'Normal',
						Click => sub { $labels->{state}->value('Normal') },
					),
					CheckBox(FLEX, DISABLED, label => 'Disabled',
						Click => sub { $labels->{state}->value('Disabled') },
					),
					Seperator(FLEX),
					$labels->{state} = Label(value => '(no input yet)'),
				),
			),
		),
		HBox(
			GroupBox(FLEX,
				Caption(label => 'orientation'),
				VBox(FLEX,
					Label(value => 'These show different orientation.'),
					CheckBox(label => 'Left',
						Click => sub { $labels->{orient}->value
							('A checkbox to the left of the label')
						},
					),
					CheckBox(DIR_REVERSE, label => 'Right',
						Click => sub { $labels->{orient}->value
							('A checkbox to the right of the label')
						},
					),
					CheckBox(DIR_FORWARD, ORIENT_VERTICAL, label => 'Above',
						Click => sub { $labels->{orient}->value
							('A checkbox above the label')
						},
					),
					CheckBox(DIR_REVERSE, ORIENT_VERTICAL, label => 'Below',
						Click => sub { $labels->{orient}->value
							('A checkbox below the label')
						},
					),
					CheckBox(Click => sub { $labels->{orient}->value
						('A checkbox with no label')
					}),
					CheckBox(Click => sub { $labels->{orient}->value
						('Another checkbox with no label')
					}),
					Seperator(FLEX),
					$labels->{orient} = Label(value => '(no input yet)'),
				),
			),
			GroupBox(FLEX,
				Caption(label => 'images'),
				VBox(FLEX,
					Label(value => 'These have images.'),
					CheckBox(
						label => 'Left',
						src   => 'images/betty_boop.xbm',
						Click => sub { $labels->{images}->value
							('A checkbox to the left of the label')
						},
					),
					CheckBox(DIR_REVERSE,
						label => 'Right',
						src   => 'images/betty_boop.xbm',
						Click => sub { $labels->{images}->value
							('A checkbox to the right of the label')
						},
					),
					CheckBox(DIR_FORWARD, ORIENT_VERTICAL,
						label => 'Above',
						src   => 'images/betty_boop.xbm',
						Click => sub { $labels->{images}->value
							('A checkbox above the label')
						},
					),
					CheckBox(DIR_REVERSE, ORIENT_VERTICAL,
						label => 'Below',
						src   => 'images/betty_boop.xbm',
						Click => sub { $labels->{images}->value
							('A checkbox below the label')
						},
					),
					CheckBox(
						src   => 'images/betty_boop.xbm',
						Click => sub { $labels->{images}->value
							('A checkbox with no label')
						},
					),
					CheckBox(
						src   => 'images/betty_boop.xbm',
						Click => sub { $labels->{images}->value
							('Another checkbox with no label')
						},
					),
					Seperator(FLEX),
					$labels->{images} = Label(value => '(no input yet)'),
				),
			),
		),
	);
}

1;
