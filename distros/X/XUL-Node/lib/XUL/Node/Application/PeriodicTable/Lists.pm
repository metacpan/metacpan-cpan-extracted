package XUL::Node::Application::PeriodicTable::Lists;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

use Data::Dumper;
sub get_demo_box {
	my $self = shift;
	my $labels = {};
	VBox(
		HBox(
			GroupBox(FLEX,
				Caption(label => 'states'),
				ListBox(rows => '5', selectedIndex => 1,
					ListItem(label => 'Normal'),
					ListItem(label => 'Selected'),
					ListItem(DISABLED, label => 'Disabled'),
					ListItem(TYPE_CHECKBOX, label => 'Checkbox',),
					ListItem
						(TYPE_CHECKBOX, label => 'Checked', checked => 'true'),
				),
			),
			GroupBox(FLEX,
				Caption(label => 'with single selection'),
				ListBox(FLEX, rows => '5',
					ListItem(label => 'Pearl'),
					ListItem(label => 'Aramis'),
					ListItem(label => 'Yakima'),
					ListItem(label => 'Tribble'),
					ListItem(label => 'Cosmo'),
					Select => sub {
						my $event = shift;
						$labels->{single}->value(
							$event->source->get_child($event->selectedIndex)->label
						);
					},
				),
				HBox(PACK_CENTER,
					$labels->{single} = Label(value => '(no input yet)'),
				),
			),
			# multiple selection events not supported
			GroupBox(FLEX, style => 'border-color: red',
				Caption(label => 'with multiple selection'),
				ListBox(FLEX, rows => '5', seltype => 'multiple',
					ListItem(label => 'Gray'),
					ListItem(label => 'Black'),
					ListItem(label => 'Holstein'),
					ListItem(label => 'Orange'),
					ListItem(label => 'White'),
				),
				HBox(align => 'center',
					Button(label => 'Select All'),
					Button(label => 'Clear All'),
					Spacer(FLEX),
					Description(value => '#'),
					Description(value => '0'),
				),
			),
		),
		GroupBox(FLEX,
			Caption(label => 'with multiple columns and a scrollbar'),
			ListBox(FLEX, rows => 5,
				ListCols(
					ListCol(FLEX),
					Splitter(class => 'tree-splitter'),
					ListCol(FLEX),
					Splitter(class => 'tree-splitter'),
					ListCol(FLEX),
				),
				ListHead(
					ListHeader(label => 'Name'),
					ListHeader(label => 'Sex'),
					ListHeader(label => 'Color'),
				),
				ListItem(
					Label(value => 'Pearl'),
					Label(value => 'Female'),
					Label(value => 'Gray'),
				),
				ListItem(
					Label(value => 'Aramis'),
					Label(value => 'Male'),
					Label(value => 'Black'),
				),
				ListItem(
					Label(value => 'Yakima'),
					Label(value => 'Male'),
					Label(value => 'Holstein'),
				),
				ListItem(
					Label(value => 'Cosmo'),
					Label(value => 'Female'),
					Label(value => 'White'),
				),
				ListItem(
					Label(value => 'Fergus'),
					Label(value => 'Male'),
					Label(value => 'Black'),
				),
				ListItem(
					Label(value => 'Clint'),
					Label(value => 'Male'),
					Label(value => 'Black'),
				),
				ListItem(
					Label(value => 'Tribble'),
					Label(value => 'Female'),
					Label(value => 'Orange'),
				),
				ListItem(
					Label(value => 'Zippy'),
					Label(value => 'Male'),
					Label(value => 'Orange'),
				),
				ListItem(
					Label(value => 'Feathers'),
					Label(value => 'Male'),
					Label(value => 'Tabby'),
				),
				ListItem(
					Label(value => 'Butter'),
					Label(value => 'Male'),
					Label(value => 'Orange'),
				),
			),
		),
	);
}

1;







