package Foo;

use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my $self = bless {}, __PACKAGE__;
    $self->{val} = 1;
    return $self;
}

sub get_val { $_[0]->{val} }
sub mul_val { $_[0]->{val} *= $_[1] }

1;

