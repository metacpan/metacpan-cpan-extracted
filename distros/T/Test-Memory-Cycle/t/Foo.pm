package Foo;

use strict;
use warnings;

sub new {
    my $class = shift;
    bless {}, $class;
}

1;
