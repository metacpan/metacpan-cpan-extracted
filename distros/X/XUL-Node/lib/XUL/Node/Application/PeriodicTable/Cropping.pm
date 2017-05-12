package XUL::Node::Application::PeriodicTable::Cropping;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

sub get_demo_box {
	my $self = shift;
	VBox(
		GroupBox(
			Caption(label => 'start'),
			Description(CROP_START, value => q{This is a one-line description. It will be cropped on the left if there isn't enough room for it.}),
			Button     (CROP_START, label => q{Now is the time for all good men to come to the aid of their party.  Mary had a little lamb whose fleece was white as snow.}),
			Label      (CROP_START, value => q{This is a one-line label. It will be cropped on the left if there isn't enough room for it.}),
		),
		GroupBox(
			Caption(label => 'center'),
			Description(CROP_CENTER, value => q{This is a one-line description. It will be cropped on the right if there isn't enough room for it.}),
			Button     (CROP_CENTER, label => q{Now is the time for all good men to come to the aid of their party.  Mary had a little lamb whose fleece was white as snow.}),
			Label      (CROP_CENTER, value => q{This is a one-line label. It will be cropped on the right if there isn't enough room for it.}),
		),
		GroupBox(
			Caption(label => 'end'),
			Description(CROP_END, value => q{And this one-line description, if there isn't enough room for it,  will be cropped in the middle.}),
			Button     (CROP_END, label => q{Now is the time for all good men to come to the aid of their party.  Mary had a little lamb whose fleece was white as snow.}),
			Label      (CROP_END, value => q{And this one-line label, if there isn't enough room for it,  will be cropped in the middle.}),
		),
	);
}

1;

