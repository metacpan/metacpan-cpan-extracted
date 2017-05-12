package MyTestRun::Plug::Base;

use strict;
use warnings;

use Moose;

extends(qw(
    Test::Run::Base::Struct
    ));

has 'first' => (is => "rw");
has 'last' => (is => "rw");

sub my_calc_first
{
    my $self = shift;

    return $self->first();
}

sub my_calc_last
{
    my $self = shift;

    return $self->last();
}

1;

