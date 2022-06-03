# $Id$
package Youri::Package::Change;

=head1 NAME

Youri::Package::Change - Package change class

=head1 DESCRIPTION

This class represent a package change.

=cut

use strict;
use warnings;
use Carp;

use constant AUTHOR => 0;
use constant TIME   => 1;
use constant TEXT   => 2;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Package::Change object.

=cut

sub new {
    my ($class, $author, $time, $text) = @_;

    return bless [
        $author,
        $time,
        $text,
    ], $class;
}

=head2 get_author()

Returns the author of this change.

=cut

sub get_author {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->[AUTHOR];
}

=head2 get_time()

Return the time of this change.

=cut

sub get_time {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->[TIME];
}

=head2 get_raw_text()

Returns the textual description of this change, as as string.

=cut

sub get_raw_text {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->[TEXT];
}

=head2 get_text_items()

Returns the textual description of this change, as as array reference of
individual changes.

=cut

sub get_text_items {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->[TEXT] =~ /
        ^
        [-+ ] \s+ # list token
        (.*)      # real text
        $
        /xmg;
}

1;
