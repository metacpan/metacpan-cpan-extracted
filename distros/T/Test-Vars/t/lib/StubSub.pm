package StubSub;

use strict;
use warnings;

use Moose::Role;

sub stub;

has stub => ( is => 'ro' );

sub foo {
    my $x = 42;
    return 0;
}

1;
