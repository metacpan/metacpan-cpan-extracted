package XAO::DO::Sub::Level;
use strict;
use warnings;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Atom');

sub method_lib ($) {
    my $self=shift;
    return XAO::Objects->new(objname => 'DepBase')
            ->combine('testlib-Sub-Level:lib',shift);
}

1;
