package XAO::DO::FakeCGI;
use strict;
use warnings;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Atom');

sub fubarize {
    my $self=shift;
    return 'fubar:'.join(' ',@_);
}

1;
