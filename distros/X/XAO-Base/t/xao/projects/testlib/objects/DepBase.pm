package XAO::DO::DepBase;
use strict;
use warnings;
use XAO::Objects;
use base XAO::Objects->load(objname => 'DepBase', sitename => 'test');

sub method_C ($) {
    my $self=shift;
    return $self->combine('testlib-DepBase-C',shift);
}

1;
