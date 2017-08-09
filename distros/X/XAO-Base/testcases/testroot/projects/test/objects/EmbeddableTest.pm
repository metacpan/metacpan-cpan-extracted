# Test object for testcases/DOConfig.pm
#
package XAO::DO::EmbeddableTest;
use strict;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Embeddable');

sub embeddable_methods ($) {
    return qw(check);
}

sub check ($$) {
    my $self=shift;
    return $self->base_config();
}

1;
