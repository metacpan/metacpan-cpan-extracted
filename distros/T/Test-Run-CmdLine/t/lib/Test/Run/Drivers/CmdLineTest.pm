package Test::Run::Drivers::CmdLineTest;

use strict;
use warnings;

use Moose;

sub runtests
{
    my $self = shift;
    return +{ 'tested' => [ @{$self->test_files()} ] };
}

1;

