package Test2::Harness::Pipeline::Validator;
use strict;
use warnings;

use parent 'Test2::Harness::Pipeline';
use Test2::Harness::HashBase qw{};

sub process {
    my $self = shift;
    return @_;
#    for my $e (@events) {
#
#    }
}

1;
