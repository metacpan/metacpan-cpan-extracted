# $Id$
package Youri::Package::File;

=head1 NAME

Youri::Package::File - Package file class

=head1 DESCRIPTION

This class represent a package file,

=cut

use strict;
use warnings;
use Carp;

use constant NAME   => 0;
use constant MODE   => 1;
use constant MD5SUM => 2;

use constant MODE_MASK => oct(170000); 
use constant MODE_DIR  => oct(40000);

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Package::File object.

=cut

sub new {
    my ($class, $name, $mode, $md5sum) = @_;

    return bless [
        $name,
        $mode,
        $md5sum,
    ], $class;
}

=head2 get_name()

Returns the name of this file.

=cut

sub get_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->[NAME];
}

=head2 get_mode()

Return the mode of this file.

=cut

sub get_mode {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->[MODE];
}

=head2 get_md5sum()

Return the md5sum of this file.

=cut

sub get_md5sum {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->[MD5SUM];
}

=head2 is_directory()

Returns a true value if this file is a directory.

=cut

sub is_directory {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    ## no critic (ProhibitBitwise)
    return ($self->[MODE] & MODE_MASK) == MODE_DIR;
}

1;
