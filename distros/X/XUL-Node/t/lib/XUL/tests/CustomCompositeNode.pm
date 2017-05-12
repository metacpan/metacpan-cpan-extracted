package XUL::tests::CustomCompositeNode;

use strict;
use warnings;
use Carp;

use XUL::Node qw(XUL::tests::CustomNode);
use base 'XUL::Node';

sub my_keys { qw(num_of_children) }

sub init {
	my ($self, %params) = @_;
    $self->add_child( CustomNode(color => 'red') )
        for 1..$params{num_of_children};
}

1;
