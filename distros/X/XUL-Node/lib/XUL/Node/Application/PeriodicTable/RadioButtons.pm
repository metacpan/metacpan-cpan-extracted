package XUL::Node::Application::PeriodicTable::RadioButtons;

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
				Caption(label => 'states'),
				RadioGroup(FLEX,
					Label(value => 'These show different states.'),
					Radio(FLEX, label => 'Selected', selected => 1,
						Click => sub { $labels->{state}->value('Selected') },
					),
					Radio(FLEX, label => 'Normal',
						Click => sub { $labels->{state}->value('Normal') },
					),
					Radio(FLEX, DISABLED, label => 'Disabled',
						Click => sub { $labels->{state}->value('Disabled') },
					),
					Seperator(FLEX),
					$labels->{state} = Description(value => '(no input yet)'),
				),
			),
			GroupBox(FLEX,
				Caption(label => 'accesskeys'),
				RadioGroup(FLEX,
					Label(value => 'These have access keys.'),
					Label(value => q{(Even if they're not marked)}),
					Radio(FLEX, label => 'Animal', accesskey => 'a',
						Click => sub { $labels->{accesskey}->value('Animal') },
					),
					Radio(FLEX, label => 'Bear', accesskey => 'b',
						Click => sub { $labels->{accesskey}->value('Bear') },
					),
					Radio(FLEX, label => 'Cat', accesskey => 'c',
						Click => sub { $labels->{accesskey}->value('Cat') },
					),
					Radio(FLEX, label => 'Dog', accesskey => 'd',
						Click => sub { $labels->{accesskey}->value('Dog') },
					),
					Radio(FLEX, label => 'Deer', accesskey => 'e',
						Click => sub { $labels->{accesskey}->value('Deer') },
					),
					Radio(FLEX, label => 'Fish', accesskey => 'f',
						Click => sub { $labels->{accesskey}->value('Fish') },
					),
					Seperator(FLEX),
					$labels->{accesskey} = Label(value => '(no input yet)'),
				),
			),
		),
		HBox(
			GroupBox(FLEX,
				Caption(label => 'orientation'),
				RadioGroup(FLEX,
					Label
						(value => 'These radiobuttons show different orientation.'),
					Radio(label => 'Left',
						Click => sub { $labels->{orient}->value
							('A radiobutton to the left of the label')
						},
					),
					Radio(FLEX, DIR_REVERSE, label => 'Right',
						Click => sub { $labels->{orient}->value
							('A radiobutton to the right of the label')
						},
					),
					Radio(DIR_FORWARD, ORIENT_VERTICAL, label => 'Above',
						Click => sub { $labels->{orient}->value
							('A radiobutton above the label')
						},
					),
					Radio(DIR_REVERSE, ORIENT_VERTICAL, label => 'Below',
						Click => sub { $labels->{orient}->value
							('A radiobutton below the label')
						},
					),
					Radio(Click => sub { $labels->{orient}->value
						('A radiobutton with no label')
					}),
					Radio(Click => sub { $labels->{orient}->value
						('Another radiobutton with no label')
					}),
					Seperator(FLEX),
					$labels->{orient} = Label(value => '(no input yet)'),
				),
			),
			GroupBox(FLEX,
				Caption(label => 'images'),
				RadioGroup(FLEX,
					Label
						(value => 'These radiobuttons show images.'),
					Radio(
						label => 'Left',
						src   => 'images/betty_boop.xbm',
						Click => sub { $labels->{images}->value
							('A radiobutton to the left of the label')
						},
					),
					Radio(FLEX, DIR_REVERSE,
						label => 'Right',
						src   => 'images/betty_boop.xbm',
						Click => sub { $labels->{images}->value
							('A radiobutton to the right of the label')
						},
					),
					Radio(DIR_FORWARD, ORIENT_VERTICAL,
						label => 'Above',
						src   => 'images/betty_boop.xbm',
						Click => sub { $labels->{images}->value
							('A radiobutton above the label')
						},
					),
					Radio(DIR_REVERSE, ORIENT_VERTICAL,
						label => 'Below',
						src   => 'images/betty_boop.xbm',
						Click => sub { $labels->{images}->value
							('A radiobutton below the label')
						},
					),
					Radio(
						src   => 'images/betty_boop.xbm',
						Click => sub { $labels->{images}->value
							('A radiobutton with no label')
						},
					),
					Radio(
						src   => 'images/betty_boop.xbm',
						Click => sub { $labels->{images}->value
							('Another radiobutton with no label')
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


__END__

			GroupBox(FLEX,
				Caption(label => 'images'),
				VBox(FLEX,
					Label(value => 'These radiobuttons show images.'),
				),
			),