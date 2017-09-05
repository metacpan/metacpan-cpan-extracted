package Test2::Harness::Pipeline;
use strict;
use warnings;

use Carp qw/croak/;

use Test2::Harness::HashBase qw{
    -job_id -job_dir -harness
};

sub process {
    my $self = shift;
    my $pkg = ref($self) || $self;
    croak "$pkg\->process() is not implemented!"
}

1;
