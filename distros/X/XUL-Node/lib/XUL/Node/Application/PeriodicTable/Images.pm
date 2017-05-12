package XUL::Node::Application::PeriodicTable::Images;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

sub get_demo_box {
	my $self = shift;
	VBox(
		GroupBox(
			Caption(label => 'The Blind Chicken'),
			HBox(
				VBox(ALIGN_CENTER,
					Image(
						style => 'width: 20px; height: 20px',
						src   => 'images/BC-R.jpg',
					),
					Label(value =>'smaller image'),
				),
				VBox(ALIGN_CENTER,
					Image(src => 'images/BC-R.jpg'),
					Label(value =>'natural-sized image'),
				),
				VBox(ALIGN_CENTER,
					Image(
						style => 'width: 200px; height: 200px',
						src   => 'images/BC-R.jpg',
					),
					Label(value =>'enlarged  image'),
				),
			),
		),
		GroupBox(
			Caption(label => 'Betty Boop'),
			HBox(
				VBox(ALIGN_CENTER,
					Image(src => 'images/betty_boop.xbm'),
					Label(value =>'natural-sized image'),
				),
				VBox(ALIGN_CENTER,
					Image(
						style => 'width: 200px; height: 200px',
						src   => 'images/betty_boop.xbm',
					),
					Label(value =>'enlarged image'),
				),
			),
		),
	);
}

1;

