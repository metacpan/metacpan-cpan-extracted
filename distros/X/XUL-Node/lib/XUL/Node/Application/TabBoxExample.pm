package XUL::Node::Application::TabBoxExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

my $Tabs = 3;

sub start {
	local $_;
	Window(
		GroupBox(FILL,
			TabBox(FILL, selectedIndex => 0,
				Tabs(
					map { Tab(label => "tab #$_") }
						(1..$Tabs),
				),
				TabPanels(FILL,
					map { TabPanel(Label(value => "tabpanel #$_")) }
						(1..$Tabs),
				),
			),
		),
	);
}

1;
