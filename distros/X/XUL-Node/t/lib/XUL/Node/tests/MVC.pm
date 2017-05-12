package XUL::Node::tests::MVC;

use strict;
use warnings;
use Carp;
use Test::More;
use XUL::Node::Application;
use XUL::Node::MVC;

use base 'Test::Class';

# binding to model ------------------------------------------------------------

sub simple_model_bind: Test {
	my $node = Label(value => ValueModel(value => 'foo'));
	is $node->value, 'foo';
}

sub change_model_after_bind: Test {
	my $node = Label(value => my $model = ValueModel);
	$model->value('bar');
	is $node->value, 'bar';
}

sub change_model_after_bind_twice: Test {
	my $node = Label(value => my $model = ValueModel);
	$model->value('bar');
	$model->value('baz');
	is $node->value, 'baz';
}

# binding to tie --------------------------------------------------------------

sub simple_tie_bind: Test {
	ValueModel tie => my $value;
	$value = 'foo';
	my $node = Label(value => $value);
	is $node->value, 'foo';
}

sub change_tie_after_bind: Test {
	ValueModel tie => my $value;
	my $node = Label;
	$node->value($value);
	$value = 'bar';
	is $node->value, 'bar';
}

sub change_tie_before_bind: Test {
	ValueModel tie => my $value;
	my $node = Label;
	$value = 'bar';
	$node->value($value);
	is $node->value, 'bar';
}

sub bind_in_constructor: Test {
	ValueModel tie => my $value, value => 'foo';
	my $node = Label value => $value;
	$value = 'bar';
	is $node->value, 'bar';
}

sub tie_and_bind_in_constructor: Test {
	my $node = Label(value => ValueModel tie => my $value);
	$value = 'bar';
	is $node->value, 'bar';
}

sub set_attribute_should_modify_model: Test {
	my $node = Label(value => ValueModel tie => my $value);
	$node->value('foo');
	is $value, 'foo';
}

sub set_attribute_with_model: Test {
	my $node = Label(value => ValueModel tie => my $value);
	$node->value('foo');
	is $node->value, 'foo';
}

sub replace_model: Test {
	my $node = Label;
	ValueModel tie => my $value1;
	ValueModel tie => my $value2;
	$value1 = 'foo';
	$node->value($value1);
	$value1 = 'bar';
	$node->value($value2);
	$value2 = 'baz';
	$value1 = 'bam';
	is $node->value, 'baz';
}

sub multiple_views: Test {
	ValueModel tie => my $value;
	my $node1 = TextBox(value => $value);
	my $node2 = TextBox(value => $value);
	$node1->value('foo');
	is $node2->value, 'foo';
}

sub multiple_views_twice_changed: Test {
	ValueModel tie => my $value;
	my $node1 = TextBox(value => $value);
	my $node2 = TextBox(value => $value);
	$node1->value('foo');
	$node2->value('bar');
	is $node1->value, 'bar';
}

# binding with an attribute ---------------------------------------------------

sub attribute_view_change: Test {
	my $value: Value;
	my $node = Label(value => $value);
	$node->value('foo');
	is $value, 'foo';
}

sub attribute_tie_change: Test {
	my $node = Label(value => my $value: Value);
	$value = 'bar';
	is $node->value, 'bar';
}

sub attribute_model_change: Test {
	my $node = Label(value => my $value: Value);
	tied($value)->value('bar');
	is $node->value, 'bar';
}

sub attributes_work_in_string_eval: Test {
	eval q{ok tied(my $value: Value = 'foo')};
	croak $@ if $@;
}

sub attributes_work_in_runtime_loaded_class: Test
	{ ok(XUL::Node::Application->create('SampleMVCApplication')->start) }

1;
