
# We define custom widgets in pure Perl and XUL, then use them!

# a button, but with a bold blue label, self increasing -----------------------

package MyCustomButton;

use XUL::Node;
use base 'XUL::Node';

# this widget is represented by the XUL Button element
# the name of its factory method is just the package name (default)
# it takes no special construction params (default)
sub my_tag { 'Button' }

sub init {
	my $self = shift;
	$self->style('color:blue; font-weight:bold');
	add_listener $self, Click => sub
		{ my $me = shift->source; $me->label( $me->label + 1 ) }
}

# a group box of custom buttons -----------------------------------------------

package MyCustomButtonBox;

use XUL::Node::MVC qw(MyCustomButton);
use base 'XUL::Node';

# this widget is represented by the XUL GroupBox
# the name of its factory method is ButtonBox
# it takes a parameter 'number' in its constructor
sub my_tag  { 'GroupBox' }
sub my_name { 'ButtonBox' }
sub my_keys { qw(number)  }

sub init {
	my ($self, %params) = @_;
	local $_;
	my $label: Value = 0;
	$self->add_child( MyCustomButton(label => $label) )
        for 1..$params{number};
}

# the application -------------------------------------------------------------

package XUL::Node::Application::CustomWidgetsExample;

use strict;
use warnings;
# custom widgets need to be imported through XUL::Node or XUL::Node::MVC
use XUL::Node::MVC qw(MyCustomButton MyCustomButtonBox);
use base 'XUL::Node::Application';

sub start {
	my $label: Value = 0;
	Window(SIZE_TO_CONTENT, VBox(
		MyCustomButton(label => $label),
		ButtonBox(number => 5),
	));
}

1;
