package Test2::Harness::Config;
use strict;
use warnings;

use Test2::Harness::HashBase qw{
    -search
    -jobs -job_class
    -preload
    -include
    -merge_output
    -quiet -color -verbose
    -timeout
    -renderer
    -parser
};

sub init {
    my $self = shift;

    $self->{+SEARCH} ||= ['test.pl', 't', 't2'];
}

1;
