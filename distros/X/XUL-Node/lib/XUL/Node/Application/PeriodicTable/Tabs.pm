package XUL::Node::Application::PeriodicTable::Tabs;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

sub get_demo_box {
	my $self = shift;
	VBox(FLEX,
		GroupBox(
			Description
				(textNode => 'This is the standard tabbox. It looks fine.'),
			GroupBox(
				TabBox(FLEX,
					Tabs(
						Tab(label => 'Default'),
						Tab(label => 'Tab'),
						Tab(label => 'Orientation'),
					),
					TabPanels(FLEX,
						Label(value => 'Default'),
						Label(value => 'Tab'),
						Label(value => 'Orientation'),
					),
				),
			),
		),
		GroupBox(
			Description(textNode => q{
				This one has been turned on its head so that the tabs 
				are on the bottom. I had to fiddle with the styles to 
				make this look decent.
			}),
			GroupBox(
				TabBox(FLEX,
					TabPanels(FLEX, style => 'border-bottom: 0px solid',
						Label(value => 'Tabs'),
						Label(value => 'on the'),
						Label(value => 'bottom'),
					),
					Tabs(FLEX, class => 'tabs-bottom',
						Tab(label => 'Tabs'  , class => 'tabs-bottom'),
						Tab(label => 'on the', class => 'tabs-bottom'),
						Tab(label => 'bottom', class => 'tabs-bottom'),
					),
				),
			),
			GroupBox(
				Description(textNode => q{
					And here are a couple with the tabs on the side.  They work, but
					they'll need a bunch of style changes to make them look reasonable.
				}),
				GroupBox(
					HBox(
						TabBox(FLEX, ORIENT_HORIZONTAL,
							Tabs(FLEX, ORIENT_VERTICAL, class => 'tabs-left',
								Tab(label => 'Tabs'  , class => 'tabs-left'),
								Tab(label => 'on the', class => 'tabs-left'),
								Tab(label => 'Left'  , class => 'tabs-left'),
							),
							TabPanels(FLEX,
								Label(value => 'Tabs'),
								Label(value => 'on the'),
								Label(value => 'Left'),
							),
						),
						Spacer(FLEX),
						TabBox(FLEX, ORIENT_HORIZONTAL, DIR_REVERSE,
							Tabs(FLEX, ORIENT_VERTICAL,
								Tab(label => 'Tabs'),
								Tab(label => 'on the'),
								Tab(label => 'Right'),
							),
							TabPanels(FLEX,
								Label(value => 'Tabs'),
								Label(value => 'on the'),
								Label(value => 'Left'),
							),
						),
					),
				),
			),
		),
	);
}

1;
