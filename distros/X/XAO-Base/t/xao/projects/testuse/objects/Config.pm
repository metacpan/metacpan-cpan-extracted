package XAO::DO::Config;
use strict;
use XAO::Objects;

use parent XAO::Objects->load(objname => 'Config', baseobj => 1);
use parent XAO::Objects->load(objname => 'Config1', include => [ qw(testuse testlib test) ]);
use parent XAO::Objects->load(objname => 'Config2', include => [ qw(testuse testlib test) ]);
use parent XAO::Objects->load(objname => 'Config3', include => [ qw(testuse testlib test) ]);

sub init ($$) {
    my $self=shift;

    $self->SUPER::init();

    $self->embed(hash => XAO::SimpleHash->new);
    $self->embedded('hash')->fill({
        xao => {
            objects => {
                include => [    # Include these projects when looking for objects
                    'testlib',
                    'test',
                ],
            },
        },
    });
}

1;
