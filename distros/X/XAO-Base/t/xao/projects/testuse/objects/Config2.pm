# Defined in testlib and overridden in testuse

package XAO::DO::Config2;
use strict;
use warnings;
use XAO::Objects;

use parent XAO::Objects->load(objname => 'Config2', baseobj => 1, include => [ qw(testlib test) ]);

sub config_2_over {
    my $self=shift;
    return $self->SUPER::config_2_over().":Use";
}

sub config_2_use {
    return 'Config2:Use';
}

1;
