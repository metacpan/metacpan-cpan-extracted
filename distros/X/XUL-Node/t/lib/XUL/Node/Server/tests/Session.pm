package XUL::Node::Server::tests::Session;

use strict;
use warnings;
use Carp;
use Test::More;
use Test::Exception;
use XUL::tests::Assert;
use XUL::Node::Server::Session;

use base 'Test::Class';

sub subject_class { 'XUL::Node::Server::Session' }

# is the right boot message sent?
sub hello_world: Test {
	is_xul
		pop->handle_boot({name => 'HelloWorld'}),
		[qw(
			E2.new.window.0
			E2.set.sizeToContent.1
			E1.new.label.E2.0
			E1.set.value.Hello_World!
		)];
}

# do we filter illegal application names?
sub application_name_security_risk: Test {
	my ($self, $subject) = @_;
	dies_ok { $subject->handle_boot({name => 'My::Illegal::App'}) };
}

# does a client event get the correct response?
sub button_example: Test {
	my ($self, $subject) = @_;
	$subject->handle_boot({name => 'ButtonExample'});
	is_xul
		$subject->handle_event({name => 'Click', source => 'E2'}),
		['E2.set.label.1'];
}

# do client events get correct responses?
sub button_example_2_clicks: Test {
	my ($self, $subject) = @_;
	$subject->handle_boot({name => 'ButtonExample'});
	$subject->handle_event({name => 'Click', source => 'E2'});
	is_xul
		$subject->handle_event({name => 'Click', source => 'E2'}),
		['E2.set.label.2'];
}

# events have side effects on widgets
sub event_side_effects_textbox: Test {
	my ($self, $subject) = @_;
	$subject->handle_boot({name => 'TextBoxExample'});
	$subject->handle_event({name => 'Change', source => 'E1', value => 'foo'});
	is $subject->event_manager->get_node('E1')->value, 'foo';
}

sub event_side_effects_checkbox: Test(2) {
	my ($self, $subject) = @_;
	$subject->handle_boot({name => 'CheckBoxExample'});
	my $check_box = $subject->event_manager->get_node('E1');
	$subject->handle_event
		({name => 'Click', source => 'E1', checked => 'true'});
	is $check_box->checked, 1, 'checked';
	$subject->handle_event({name => 'Click', source => 'E1', checked => ''});
	is $check_box->checked, 0, 'unchecked';
}

# does destroying a session destroy all widgets?
sub destroy: Test {
	my ($self, $subject) = @_;
	$subject->handle_boot({name => 'HelloWorld'});
	my $node = $subject->get_node('E2');
	$subject->destroy;
	ok $node->is_destroyed;
}

1;

