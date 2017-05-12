package XUL::Node::Application::PeriodicTable::StacksAndDecks;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

sub get_demo_box {
	my $self = shift;
	my $deck;
	HBox(
		GroupBox(
			Caption(label => 'stack'),
			Stack(
				Image(src => 'images/betty_boop.xbm'),
				Image(src => 'images/BC-R.jpg'),
				Label(
					value => 'Chicks',
					style => 'font-weight:bold',
					top   => '80px',
				),
				Button(
					image => 'images/chick.png',
					left  => '60px',
					top   => '60px',
					style => 'height: 30px; width:25px; background-color: #663333',
				),
			),
		),
		GroupBox(
			Caption(label => 'deck'),
			$deck = Deck(
				Image(src => 'images/betty_boop.xbm'),
				Image(src => 'images/BC-R.jpg'),
				Label(
					value => 'Chicks',
					style => 'font-weight:bold',
					top   => '80px',
				),
				Button(
					image => 'images/chick.png',
					left  => '60px',
					top   => '60px',
					style => 'height: 30px; width:25px; background-color: #663333',
				),
			),
			RadioGroup(FLEX, ORIENT_HORIZONTAL, selectedIndex => 0,
				Radio(label => 0, Click => sub { $deck->selectedIndex(0) }),
				Radio(label => 1, Click => sub { $deck->selectedIndex(1) }),
				Radio(label => 2, Click => sub { $deck->selectedIndex(2) }),
				Radio(label => 3, Click => sub { $deck->selectedIndex(3) }),
			),
		),
	);
}

1;
