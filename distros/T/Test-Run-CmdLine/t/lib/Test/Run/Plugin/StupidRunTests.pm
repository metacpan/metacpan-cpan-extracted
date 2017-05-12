package Test::Run::Plugin::StupidRunTests;

use strict;
use warnings;

sub runtests
{
    my $self = shift;
    return +{ 'tested' => [ @{$self->test_files()} ] };
}

1;

