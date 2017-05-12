package XML::RSS::Private::Output::Roles::ModulesElems;

use strict;
use warnings;

sub _out_modules_elements_if_supported {
    my ($self, $top_elem) = @_;

    return $self->_out_modules_elements($top_elem);
}

1;

