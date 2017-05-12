package XUL::Node::Application::MVCTextBoxExample;

use strict;
use warnings;
use XUL::Node::MVC;

use base 'XUL::Node::Application';

sub start {
	local $_;
	my $value: Value = 'change me';
	Window(VBox(map { TextBox(value => $value) } 1..10));
}

1;
