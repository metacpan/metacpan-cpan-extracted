package XUL::Node::Application::PeriodicTable::Grids;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

sub get_demo_box {
	my $self = shift;
	VBox(
		GroupBox(
			Caption(label => 'data in the rows'),
			Grid(
				Columns(Column(FLEX), Column(FLEX), Column(FLEX), Column(FLEX)),
				Rows(
					Row(
						Button(label => 'Name'),
						Button(label => 'Sex'),
						Button(label => 'Color'),
						Button(label => 'Description'),
					),
					Row(
						Label(value => 'Pearl'),
						Label(value => 'Female'),
						Label(value => 'Gray'),
						Label(value => 'Frumpy'),
					),
					Row(
						Label(value => 'Aramis'),
						Label(value => 'Male'),
						Label(value => 'Black'),
						Label(value => 'Cute'),
					),
					Row(
						Label(value => 'Yakima'),
						Label(value => 'Male'),
						Label(value => 'Holstein'),
						Label(value => 'Handsome'),
					),
					Row(
						Label(value => 'Cosmo'),
						Label(value => 'Female'),
						Label(value => 'White'),
						Label(value => 'Round'),
					),
					Row(
						Label(value => 'Fergus'),
						Label(value => 'Male'),
						Label(value => 'Black'),
						Label(value => 'Long'),
					),
					Row(
						Label(value => 'Clint'),
						Label(value => 'Male'),
						Label(value => 'Black'),
						Label(value => 'Young'),
					),
					Row(
						Label(value => 'Tribble'),
						Label(value => 'Female'),
						Label(value => 'Orange'),
						Label(value => 'Frumpy'),
					),
					Row(
						Label(value => 'Zippy'),
						Label(value => 'Male'),
						Label(value => 'Orange'),
						Label(value => 'Playful'),
					),
					Row(
						Label(value => ''),
						Label(value => ''),
						Label(value => ''),
						Label(value => ''),
					),
				),
			),
		),
		GroupBox(
			Caption(label => 'data in the columns'),
			Grid(
				Rows(Row, Row, Row, Row),
				Columns(
					Column(
						Button(label => 'Name'),
						Button(label => 'Sex'),
						Button(label => 'Color'),
						Button(label => 'Description'),
					),
					Column(
						Label(value => 'Pearl'),
						Label(value => 'Female'),
						Label(value => 'Gray'),
						Label(value => 'Frumpy'),
					),
					Column(
						Label(value => 'Aramis'),
						Label(value => 'Male'),
						Label(value => 'Black'),
						Label(value => 'Cute'),
					),
					Column(
						Label(value => 'Yakima'),
						Label(value => 'Male'),
						Label(value => 'Holstein'),
						Label(value => 'Handsome'),
					),
					Column(
						Label(value => 'Cosmo'),
						Label(value => 'Female'),
						Label(value => 'White'),
						Label(value => 'Round'),
					),
					Column(
						Label(value => 'Fergus'),
						Label(value => 'Male'),
						Label(value => 'Black'),
						Label(value => 'Long'),
					),
					Column(
						Label(value => 'Clint'),
						Label(value => 'Male'),
						Label(value => 'Black'),
						Label(value => 'Young'),
					),
					Column(
						Label(value => 'Tribble'),
						Label(value => 'Female'),
						Label(value => 'Orange'),
						Label(value => 'Frumpy'),
					),
					Column(
						Label(value => 'Zippy'),
						Label(value => 'Male'),
						Label(value => 'Orange'),
						Label(value => 'Playful'),
					),
				),
			),
		),
	);
}

1;

