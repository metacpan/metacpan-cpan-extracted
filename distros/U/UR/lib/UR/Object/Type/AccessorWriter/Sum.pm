
package UR::Object::Type::AccessorWriter::Sum;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;

sub calculate {
    my $self = shift;
    my $object = shift;
    my $properties = shift;
    my $sum = 0;
    for my $property (@$properties) {
        $sum += $object->$property
    }   
    return $sum;
};

1;

=pod

=head1 NAME

UR::Object::Type::AccessorWriter::Sum - Implements a calculation accessor which sums the values of its properties

=cut
