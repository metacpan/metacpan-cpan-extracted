package UML::Sequence::Activation;
use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

UML::Sequence::Activation - a helper class to support UML::Sequence

=head1 SYNOPSIS

    use UML::Sequence::Activation;
    my $activation = UML::Sequence::Activation->new();
    $activation->starts(2);
    ...

=head1 DESCRIPTION

This class keeps track of the start, end, offset, and bounds for an activation
in the sequence diagram.  It is a data container (a node), so it provides
direct access to its attributes.  The constructor ignores all arguments,
use accessors or direct access to insert and check the values.

=head1 new

Trivial constructor, taking nothing, returning a blessed reference to an
empty hash.

=cut

sub new {
  my $class = shift;
  my $self  = {};

  bless $self, $class;
}

=head1 starts

Accessor to set or check the starting attribute.  Always returns the value.
This is the arrow number at the top of the activation.

=cut
sub starts {
  my $self    = shift;
  my $new_val = shift;

  if (defined $new_val) {
    $self->{STARTING} = $new_val;
  }
  return $self->{STARTING};
}

=head1 ends

Accessor to set or check the ending attribute.  Always returns the value.
This is the arrow number at the bottom of the activation.

=cut
sub ends {
  my $self    = shift;
  my $new_val = shift;

  if (defined $new_val) {
    $self->{ENDING} = $new_val;
  }
  return $self->{ENDING};
}

=head1 offset

Accessor to set or check the offset attribute.  Always returns the value.
This is the number of stacked activations.  An offset of zero means the
activation is centered over the lifelife.  An offset of one means a self
call activation is on top of the original call.  The activation should
be pushed to the right (it should be offset).

=cut
sub offset {
  my $self    = shift;
  my $new_val = shift;

  if (defined $new_val) {
    $self->{OFFSET} = $new_val;
  }
  return $self->{OFFSET};
}

=head1 find_offset

This class method takes a reference to an array of activations and returns
the number of them which are open (have undef ends attribute).  Pass in the
activations for your class, receive the offset number a new activation.

=cut

sub find_offset {
    my $class       = shift;  # ignored
    my $activations = shift;
    my $offset      = 0;

    return 0 unless defined $activations;

    my @acts = @$activations;  # make a copy so we can pop
        while (@acts) {
            my $act = pop @acts;
            if (not defined $act->ends()) {
                $offset++;
                next;
            }
        }
    return $offset;
}

=head1 find_bounds

This class method takes a reference to an array of activations and returns
the minimum starts and maximum ends attributes for the set.

=cut

sub find_bounds {
    my $class       = shift;
    my $activations = shift;
    my ($min, $max);

    foreach my $activation (@$activations) {
        if (not defined $min or $min > $activation->starts()) {
            $min = $activation->starts();
        }
        if (not defined $max or $max < $activation->starts()) {
            $max = $activation->ends();
        }
    }
    return ($min, $max);
}

1;

=head1 AUTHOR

Phil Crow, <philcrow2000@yahoo.com>

=head1 COPYRIGHT

Copyright 2003, Philip Crow, all rights reserved.  You may modify and/or
redistribute this code in the same manner as Perl itself.

=cut
