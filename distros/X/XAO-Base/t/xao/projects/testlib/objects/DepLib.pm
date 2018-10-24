package XAO::DO::DepLib;
use strict;
use warnings;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Atom');

sub method_D ($) {
    my $self=shift;
    my $obj=XAO::Objects->new(objname => 'DepBase');
    return $obj->combine('testlib-DepLib-D',shift);
}

1;
