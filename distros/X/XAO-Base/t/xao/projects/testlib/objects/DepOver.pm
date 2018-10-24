package XAO::DO::DepOver;
use strict;
use warnings;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Atom');

sub method_X ($) {
    my $self=shift;
    return 'testlib:'.(shift//'<no-arg>');
}

1;
