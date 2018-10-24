package XAO::DO::Local;
use strict;
use warnings;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Atom');

sub method_local ($) {
    my $self=shift;
    return 'local:'.(shift // '<no-arg>');
}

1;
