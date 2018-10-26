package XAO::DO::Sub::Level;
use strict;
use warnings;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Sub::Level', baseobj => 1);

sub method_use ($) {
    my $self=shift;
    return XAO::Objects->new(objname => 'DepBase')
            ->combine('testuse-Sub-Level:use',shift);
}

1;
