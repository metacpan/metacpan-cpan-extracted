package XML::XMetaL::Utilities::Filter::Element;

use base 'XML::XMetaL::Utilities::Filter::Base';

use strict;
use warnings;

use Carp;

use XML::XMetaL::Utilities qw(:dom_node_types);

use constant TRUE  => 1;
use constant FALSE => 0;

# Constructor is in super class

sub accept {
    my ($self, $node) = @_;
    my $accept = eval {$node->{nodeType} == DOMELEMENT ? TRUE : FALSE;};
    croak $@ if $@;
    return $accept;
}

1;