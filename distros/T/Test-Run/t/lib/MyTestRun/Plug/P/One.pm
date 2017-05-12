package MyTestRun::Plug::P::One;

use strict;
use warnings;

use MRO::Compat;


sub my_calc_first
{
    my $self = shift;

    return "First is {{{" . $self->next::method() . "}}}";
}

1;
