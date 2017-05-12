package XUL::Node::Server::tests::NodeState;

use strict;
use warnings;
use Carp;
use Test::More;
use XUL::tests::Assert;

use base 'Test::Class';

sub subject_class  { 'XUL::Node::Server::NodeState' }
sub subject_params { id => 'E2' }

sub init_subject_state {
	my ($self, $subject) = @_;
	$subject->set_parent_id('E1');
	$subject->set_tag('Label');
}

sub create: Test {
	my ($self, $subject) = @_;
	is_xul $subject->flush, ['E2.new.label.E1'];
}

sub change: Test {
	my ($self, $subject) = @_;
	$subject->flush;
	$subject->set_attribute(key1 => 'value1');
	$subject->set_attribute(key2 => 'value2');
	is_xul $subject->flush, [qw(E2.set.key1.value1 E2.set.key2.value2)];
}

sub flush_twice: Test {
	my ($self, $subject) = @_;
	$subject->set_attribute(foo => 'bar');
	$subject->flush;
	is $subject->flush, '';
}

sub is_destroyed: Test(2) {
	my ($self, $subject) = @_;
	ok !$subject->is_destroyed, 'before set_destoyed';
	$subject->set_destroyed;
	ok $subject->is_destroyed, 'after set_destoyed';
}

sub bye_command: Test {
	my ($self, $subject) = @_;
	$subject->flush;
	$subject->set_destroyed;
	is_xul $subject->flush, ['E2.bye'];
}

sub bye_command_before_paint: Test {
	my ($self, $subject) = @_;
	$subject->set_destroyed;
	is_xul $subject->flush, [];
}

1;

