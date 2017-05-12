package XUL::Node::Application::PeriodicTable;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

sub get_demo_panels_config {
	[Welcome        => 'Welcome'          ],
	[BoxLayout      => 'Box Layout'       ],
	[Buttons        => 'Buttons'          ],
	[CheckBoxes     => 'CheckBoxes'       ],
	[ColorPickers   => 'ColorPickers'     ],
	[Cropping       => 'Cropping'         ],
	[Grids          => 'Grids'            ],
	[Images         => 'Images'           ],
	[Labels         => 'Labels'           ],
	[Lists          => 'Lists'            ],
	[MenuBars       => 'MenuBars, etc.'   ],
	[ProgressMeters => 'ProgressMeters'   ],
	[RadioButtons   => 'RadioButtons'     ],
	[Scrolling      => 'Scrolling'        ],
	[Splitters      => 'Splitters'        ],
	[StacksAndDecks => 'Stacks and Decks' ],
	[Tabs           => 'Tabs'             ],
	[TextBoxes      => 'TextBoxes'        ],
}

sub start {
	my $self = shift;
	local $_;
	my @config = $self->get_demo_panels_config,
	my $deck;
	Window(
		HBox(FILL,
			ListBox(ALIGN_STRETCH, FLEX, selectedIndex => 0,
				Select => sub { $self->switch_demo($deck, shift->selectedIndex) },
				map { ListItem(label => $_->[1]) } @config,
			),
			Splitter,
			$deck = Deck(ALIGN_STRETCH, flex => 10, map { Box(FILL) } @config),
		),
	);
	$self->switch_demo($deck, 0);
}

# lazy load the demo tabs
sub switch_demo {
	my ($self, $deck, $index) = @_;
	my $demo_tabbox_parent = $deck->get_child($index);
	unless ($demo_tabbox_parent->child_count) {
		my ($name, $label) = @{($self->get_demo_panels_config)[$index]};
		$demo_tabbox_parent->add_child($self->get_demo_tabbox($name, $label));
	}
	$deck->selectedIndex($index);
}

sub get_demo_tabbox {
	my ($self, $name, $label) = @_;
	return TabBox(FILL, selectedIndex => 0,
		Tabs(
			Tab(label => 'Examples'),
			Tab(label => 'Source'),
		),
		TabPanels(FILL,
			VBox(FILL,
				style => 'overflow: auto; background-color: -moz-Dialog',
				$self->get_demo_box($name, $label),
			),
			Box(FILL,
				style => 'overflow: auto',
				$self->get_source_box($name),
			),
		),
	),
}

sub get_demo_box {
	my ($self, $name, $label) = @_;
	my $class = $self->get_demo_package_name($name);
	eval "use $class";
	croak "cannot use: [$class]: $@" if $@;
	return (
		HTML_H1(textNode => "XUL-Node $label"),
		$class->new->get_demo_box,
	);
}

sub get_source_box {
	my ($self, $name) = @_;
	(my $file = $self->get_demo_package_name($name). '.pm') =~ s|::|/|g;
	$file = $INC{$file};
	open F, $file or die "can't open source file [$file]: $!";
	my $value = join '', <F>;
	$value =~ s/\t/   /g;
	close F;
	return HTML_Pre(textNode => $value, style => '-moz-user-focus: normal');
}

sub get_demo_package_name { __PACKAGE__. '::'. pop }

1;
