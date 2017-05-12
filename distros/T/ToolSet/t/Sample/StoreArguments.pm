package t::Sample::StoreArguments;
use strict;
use warnings;

our @use_arguments;

sub import {
    my $class = shift;
    @use_arguments = @_;
}

1;
