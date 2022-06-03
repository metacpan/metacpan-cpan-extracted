# $Id$
package Youri::Package::Relationship;

=head1 NAME

Youri::Package::Relationship - Package relationship class

=head1 DESCRIPTION

This class represent a relationship from the package owning it to another
package.

=cut

use strict;
use warnings;
use Carp;

use constant NAME  => 0;
use constant RANGE => 1;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Package::Relationship object.

=cut

sub new {
    my ($class, $name, $range) = @_;

    return bless [
        $name,
        $range
    ], $class;
}

=head2 get_name()

Returns the name of the package this relationship applies to.

=cut

sub get_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->[NAME];
}

=head2 get_range()

Returns the revision range for which this relationship applies.

=cut

sub get_range {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->[RANGE];
}

1;
