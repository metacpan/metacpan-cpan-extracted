package TestClass;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless { foo => 'bar' }, $class;
}

sub getter {
    my ( $self, $attr ) = @_;
    return $self->{$attr};
}

sub echo {
    my ( $self, $value ) = @_;
    return $value;
}

sub get  { }
sub set  { }
sub next { }

sub once   { }
sub twice  { }
sub thrice { }

1;
