package XUL::Node::Application::ButtonExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

sub start {
	my $i = 0;
	Window(SIZE_TO_CONTENT,
		HBox(ALIGN_CENTER,
			Label (value => 'click to increment button label'),
			Button(label => $i, Click => sub { shift->source->label(++$i) }),
		),
	);
}

1;
