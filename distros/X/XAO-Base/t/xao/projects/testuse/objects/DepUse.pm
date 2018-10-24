package XAO::DO::DepUse;
use strict;
use warnings;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Atom');

sub method_E ($) {
    my $self=shift;
    my $obj=XAO::Objects->new(objname => 'DepBase');
    return $obj->combine('testuse-DepUse-E',shift);
}

1;
