package XAO::DO::Config;
use strict;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Config', baseobj => 1);

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
