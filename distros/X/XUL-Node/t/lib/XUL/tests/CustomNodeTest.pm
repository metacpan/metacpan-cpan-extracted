package XUL::tests::CustomNodeTest;

use strict;
use warnings;
use Carp;
use Test::More;
use XUL::Node qw(XUL::tests::CustomNode);

use base 'Test::Class';

sub subject_class { 'XUL::tests::CustomNode' }

sub value: Test { is pop->value, 'foo'   }
sub tag  : Test { is pop->tag  , 'Label' }

sub set_attribute: Test {
	my ($self, $subject) = @_;
	$subject->value('bar');
	is $subject->value, 'bar';
}

sub factory_create: Test {
	my $self = shift;
	my $node = CustomNode;
	is $node->value, 'foo';
}

sub adding_to_parent: Test {
	my $self = shift;
	my $box  = Box;
	$box->add_child(CustomNode);
	is $box->get_child(0)->tag, 'Label';
}

sub chain_of_responsibility_on_create_params: Test {
	my $self = shift;
	my $subject = CustomNode(color => 'red');
	is $subject->style, 'color:red';
}

1;