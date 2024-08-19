package mykura;
use strict;
use warnings;

use kura ();

sub import {
    my $pkg = shift;
    my $caller = caller;

    local $kura::EXPORTER_CLASS = 'Exporter::Tiny';
    kura->import_into($caller, @_);
}

1;
