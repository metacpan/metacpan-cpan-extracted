
package UR::Object::Type::AccessorWriter::Product;

use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

sub calculate {
    my $self = shift;
    my $object = shift;
    my $properties = shift;
    my $total = 1;
    for my $property (@$properties) {
        $total *= $object->$property
    }   
    return $total;
};

1;

=pod

=head1 NAME

UR::Object::Type::AccessorWriter::Product - Implements a calculation accessor which multiplies the values of its properties

=cut
