package Test::Run::CmdLine::Plugin::Super;

use strict;
use warnings;

use Moose;

sub BUILD
{
    my $self = shift;

    $self->add_to_backend_plugins("Super");
}

1;

