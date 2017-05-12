package Test::Run::CmdLine::Plugin::BarField;

use strict;
use warnings;

use Moose;

sub BUILD
{
    my $self = shift;

    $self->add_to_backend_plugins("BarField");
}

1;

