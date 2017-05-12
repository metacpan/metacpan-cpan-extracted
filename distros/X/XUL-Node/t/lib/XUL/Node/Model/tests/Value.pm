package XUL::Node::Model::tests::Value;

use strict;
use warnings;
use Carp;
use Test::More;
use XUL::Node;
use XUL::Node::MVC;
use XUL::Node::Model::Value;

use base 'Test::Class';

sub subject_class  { 'XUL::Node::Model::Value' }
sub subject_params { value => 'foo' }

# simple public API -----------------------------------------------------------

sub create: Test {
	my ($self, $subject) = @_;
	is $subject->value, 'foo';
}

sub change: Test {
	my ($self, $subject) = @_;
	$subject->value('bar');
	is $subject->value, 'bar';
}

# model maker -----------------------------------------------------------------

sub factory_create: Test {
	my $self = shift;
	my $subject = ValueModel value => 'foo';
	is $subject->value, 'foo';
}

sub factory_change: Test {
	my $self = shift;
	my $subject = ValueModel;
	$subject->value('bar');
	is $subject->value, 'bar';
}

# tie API ---------------------------------------------------------------------

sub tie_create: Test(2) {
	my $self = shift;
	my $subject = tie
		my $subject_as_scalar, 'XUL::Node::Model::Value', value => 'foo';
	is $subject_as_scalar, 'foo', 'tie_create as scalar';
	is $subject->value, 'foo', 'tie_create as object';
}

sub tie_change: Test(2) {
	my $self = shift;
	my $subject = tie my $subject_as_scalar, 'XUL::Node::Model::Value';
	$subject_as_scalar = 'bar';
	is $subject_as_scalar, 'bar', 'tie_change as scalar';
	is $subject->value, 'bar', 'tie_change as object';
}

# tie maker tests -------------------------------------------------------------

sub tie_maker_create: Test(2) {
	my $self = shift;
	my $subject = ValueModel tie => my $subject_as_scalar, value => 'foo';
	is $subject_as_scalar, 'foo', 'tie_maker_create as scalar';
	is $subject->value, 'foo', 'tie_maker_create as object';
}

sub tie_maker_change: Test(2) {
	my $self = shift;
	my $subject = ValueModel tie => my $subject_as_scalar;
	$subject_as_scalar = 'bar';
	is $subject_as_scalar, 'bar', 'tie_maker_change as scalar';
	is $subject->value, 'bar', 'tie_maker_change as object';
}

# attribute interface ---------------------------------------------------------

sub attribute_create: Test {
	my $self = shift;
	my $subject: Value = 'foo';
	is tied($subject)->value, 'foo';
}

sub attribute_create_with_value: Test {
	my $self = shift;
	my $subject: Value(value => 'foo');
	is tied($subject)->value, 'foo';
}

sub attribute_create_with_variable_key_or_value_does_not_work: Test {
	my $self = shift;
	my ($key, $value) = (value => 'foo');
	my $subject: Value($key => $value);
	isnt tied($subject)->value, 'foo';
}

sub attribute_change: Test {
	my $self = shift;
	my $subject: Value;
	$subject = 'bar';
	is tied($subject)->value, 'bar';
}

# listenable ------------------------------------------------------------------

sub listen_to_change: Test {
	my ($self, $subject) = @_;
	my $changed;
	add_listener $subject, Change => sub { $changed = shift->value };
	$subject->value('bar');
	is $changed, 'bar';
}

sub listen_to_change_tied: Test {
	my $self = shift;
	my $subject = ValueModel tie => my $subject_as_scalar, value => 'foo';
	my $changed;
	add_listener $subject, Change => sub { $changed = shift->value };
	$subject_as_scalar = 'bar';
	is $changed, 'bar';
}

1;