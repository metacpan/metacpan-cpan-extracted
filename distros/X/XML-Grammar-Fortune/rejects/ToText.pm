package rejects::ToText;

use strict;
use warnings;

sub _append_format_node
{
    my ($self, $delim, $node) = @_;

    return $self->_append_different_formatting_node($delim, $delim, $node);
}

1;

