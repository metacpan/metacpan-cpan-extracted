package XUL::Node::Application::PeriodicTable::Buttons;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

sub get_demo_box {
	my $self = shift;
	my $labels = {};
	VBox(FILL,
		GroupBox(
			Caption(label => 'These buttons tab oddly.'),
			HBox(
				Button(FLEX, label => '6', tabindex => 6,
					Click => sub { $labels->{tab}->value(6) },
				),
				Button(FLEX, label => '3', tabindex => 3,
					Click => sub { $labels->{tab}->value(3) },
				),
				Button(FLEX, label => '4', tabindex => 4,
					Click => sub { $labels->{tab}->value(4) },
				),
				Button(FLEX, label => '2', tabindex => 2,
					Click => sub { $labels->{tab}->value(2) },
				),
				Button(FLEX, label => '5', tabindex => 5,
					Click => sub { $labels->{tab}->value(5) },
				),
				Button(FLEX, label => '1', tabindex => 1,
					Click => sub { $labels->{tab}->value(1) },
				),
			),
			HBox(PACK_CENTER,
				$labels->{tab} = Label(value => '(no input yet)'),
			),
		),
		GroupBox(
			Caption(label => 'These buttons have access keys.'),
			HBox(
				Button(FLEX, label => 'Animal', accesskey => 'a',
					Click => sub { $labels->{accesskey}->value('Animal') },
				),
				Button(FLEX, label => 'Bear', accesskey => 'b',
					Click => sub { $labels->{accesskey}->value('Bear') },
				),
				Button(FLEX, label => 'Cat', accesskey => 'c',
					Click => sub { $labels->{accesskey}->value('Cat') },
				),
				Button(FLEX, label => 'Dog', accesskey => 'd',
					Click => sub { $labels->{accesskey}->value('Dog') },
				),
				Button(FLEX, label => 'Deer', accesskey => 'e',
					Click => sub { $labels->{accesskey}->value('Deer') },
				),
				Button(FLEX, label => 'Fish', accesskey => 'f',
					Click => sub { $labels->{accesskey}->value('Fish') },
				),
			),
			HBox(PACK_CENTER,
				$labels->{accesskey} = Label(value => '(no input yet)'),
			),
		),
		HBox(
			GroupBox(FLEX, 
				Caption(label => 'These show different states.'),
				HBox(
					Button(FLEX, label => 'Default', default => 1,
						Click => sub { $labels->{state}->value('Default') },
					),
					Button(FLEX, label => 'Checked', checked => 1,
						Click => sub { $labels->{state}->value('Checked') },
					),
					Button(FLEX, label => 'Normal',
						Click => sub { $labels->{state}->value('Normal') },
					),
					Button(FLEX, DISABLED, label => 'Disabled',
						Click => sub { $labels->{state}->value('Disabled') },
					),
				),
				HBox(PACK_CENTER,
					$labels->{state} = Label(value => '(no input yet)'),
				),
			),
			GroupBox(FLEX, 
				Caption(label => 'These are menubuttons.'),
				HBox(
					Button(TYPE_MENU, FLEX, label => 'Menu',
						MenuPopup(
							MenuItem(label => 'Option 1'),
							MenuItem(label => 'Option 2'),
							MenuItem(label => 'Option 3'),
							MenuItem(label => 'Option 4'),
						),
						Select => sub {
							my $event = shift;
							$labels->{menu}->value(
								$event->source->first_child->
								get_child($event->selectedIndex)->label
							);
						},
					),
					Button(TYPE_MENU_BUTTON, FLEX, label => 'MenuButton',
						MenuPopup(
							MenuItem(label => 'Option A'),
							MenuItem(label => 'Option B'),
							MenuItem(label => 'Option C'),
							MenuItem(label => 'Option D'),
						),
						Select => sub {
							my $event = shift;
							$labels->{menu}->value(
								$event->source->first_child->
								get_child($event->selectedIndex)->label
							);
						},
						Click => sub
							{ $labels->{menu}->value('MenuButton clicked') },
					),
				),
				HBox(PACK_CENTER,
					$labels->{menu} = Label(value => '(no input yet)'),
				),
			),
		),
		GroupBox(
			Caption(label => 'These buttons show different labeling.'),
			HBox(PACK_CENTER,
				VBox(
					Button(FLEX, label => 'No Image',
						Click => sub { $labels->{style}->value
							('A button with a label only')
						},
					),
					Button(label => 'Left', image => 'images/betty_boop.xbm',
						Click => sub { $labels->{style}->value
							('A button with both an image and a label')
						},
					),
					Button(DIR_REVERSE, label => 'Right',
						image => 'images/betty_boop.xbm',
						Click => sub { $labels->{style}->value
							('A button with the image to the right of the label')
						},
					),
				),
				VBox(
					Button(ORIENT_VERTICAL, DIR_FORWARD,
						label => 'Above',
						image => 'images/betty_boop.xbm',
						Click => sub { $labels->{style}->value
							('A button with the image above the label')
						},
					),
					Button(ORIENT_VERTICAL, DIR_REVERSE,
						label => 'Below',
						image => 'images/betty_boop.xbm',
						Click => sub { $labels->{style}->value
							('A button with the image below the label')
						},
					),
				),
				VBox(
					Button(FLEX,
						Click => sub { $labels->{style}->value
							('A button with neither image nor label')
						},
					),
					Button(image => 'images/betty_boop.xbm',
						Click => sub { $labels->{style}->value
							('A button with image only')
						},
					),
					Button(Label(width => 50, textNode => 'Wrapped Label'),
						Click => sub { $labels->{style}->value
							('A button with a multi-line, wrapped label')
						},
					),
				),
				# looks like a moz bug- despite the fact that DOM calls are
				# called in the correct order, they appear in the wrong order
				VBox(
					Button(FLEX, ORIENT_VERTICAL,
						Label(value => 'This'),
						Label(value => 'is'),
						Label(value => 'a'),
						Label(value => 'button'),
						Click => sub { $labels->{style}->value
							('Another button with a multi-line label')
						},
					),
				),
			),
			HBox(PACK_CENTER,
				$labels->{style} = Label(value => '(no input yet)'),
			),
		),
	);
}

1;
