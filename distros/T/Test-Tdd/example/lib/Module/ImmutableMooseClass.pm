package Module::ImmutableMooseClass;
use strict;
use warnings FATAL => 'all';

use Moose;

has counter => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;