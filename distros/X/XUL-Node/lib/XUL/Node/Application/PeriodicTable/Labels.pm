package XUL::Node::Application::PeriodicTable::Labels;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

sub get_demo_box {
	my $self = shift;
	VBox(
		GroupBox(
			Description(textNode => q{
				This is a multi-line description.
				It should wrap if there isn't enough room to put it in one line.
				Let's put in another sentence for good measure.
			}),
		),
		GroupBox(
			Label(textNode => q{
				This is a multi-line label.
				It should wrap if there isn't enough room to put it in one line.
				Let's put in another sentence for good measure.
			}),
			Label(DISABLED, textNode => q{
				This label should be portrayed as disabled.
			}),
		),
	);
}

1;
