package UR::Util::ArrayRefIterator;

use strict;
use warnings;
use UR;

class UR::Util::ArrayRefIterator {
    has => [
        arrayref => {
            is => 'UR::Value::ARRAY',
        },
        position => {
            is => 'Integer',
            is_optional => 1,
            default => 0,
        },
    ],
    id_by => 'arrayref',
};

sub next {
    my $self = shift;

    my @ar = @{$self->arrayref};
    my $val = $ar[$self->position];
    $self->position($self->position + 1);

    return $val;
}

1;
