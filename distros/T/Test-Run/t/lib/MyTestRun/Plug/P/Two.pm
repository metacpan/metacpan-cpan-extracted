package MyTestRun::Plug::P::Two;

use strict;
use warnings;

use MRO::Compat;


sub my_calc_last
{
    my $self = shift;

    return "If you want the last name, it is: " . $self->next::method();
}

1;

