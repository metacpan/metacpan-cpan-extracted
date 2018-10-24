package XAO::DO::DepBase;
use strict;
use warnings;
use XAO::Objects;
use base XAO::Objects->load(objname => 'DepBase', baseobj => 1);

sub method_B ($) {
    my $self=shift;
    return $self->combine('testuse-DepBase-B',shift);
}

sub method_D ($) {
    my $self=shift;
    return $self->combine('testuse-DepBase-D',shift);
}

1;
