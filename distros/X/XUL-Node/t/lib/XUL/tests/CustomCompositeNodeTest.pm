package XUL::tests::CustomCompositeNodeTest;

use strict;
use warnings;
use Carp;
use Test::More;
use XUL::Node qw(XUL::tests::CustomCompositeNode);

use base 'Test::Class';

sub factory_create: Test {
	my $self = shift;
	my $node = CustomCompositeNode(num_of_children => 3);
	is $node->child_count, 3;
}

1;
