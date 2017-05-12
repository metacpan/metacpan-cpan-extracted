package XUL::tests::CustomNode;

use strict;
use warnings;
use Carp;

use base 'XUL::Node';

sub my_tag  { 'Label' }
sub my_keys { qw(color) }

sub init {
	my ($self, %params) = @_;
    my $color = $params{color} || 'blue';
	$self->value('foo')->style("color:$color");
}

1;
