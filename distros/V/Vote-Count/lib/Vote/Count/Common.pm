use strict;
use warnings;
use 5.022;

package Vote::Count::Common;
use Moose::Role;

use feature qw /postderef signatures/;
no warnings 'experimental';

use Storable 3.15 'dclone';

# ABSTRACT: Role shared by Count and Matrix for common functionality. See Vote::Count Documentation.

our $VERSION='1.09';

=head1 NAME

Vote::Count::Common

=head1 VERSION 1.09

=head1 Synopsis

This Role is consumed by Vote::Count and Vote::Count::Matrix. It provides common methods for the Active Set.

=cut

has 'Active' => (
  is      => 'ro',
  isa     => 'HashRef',
  lazy    => 1,
  builder => '_defaultactive',
);

sub _defaultactive ( $self ) { return dclone $self->BallotSet()->{'choices'} }

sub SetActive ( $self, $active ) {
  # Force deref
  $self->{'Active'} = dclone $active;
  # if there is a child PairMatrix, update it too.
  if ( defined $self->{'PairMatrix'}) { 
    $self->{'PairMatrix'}{'Active'} = $self->{'Active'} 
  }
}

sub ResetActive ( $self ) { 
  $self->{'Active'} = $self->_defaultactive();
}

# I was typing the equivalent too often. made a method.
sub SetActiveFromArrayRef ( $self, $active ) {
  $self->SetActive( { map { $_ => 1 } $active->@* } );
}

sub GetActive ( $self ) {
  # Force deref
  my $active = $self->Active();
  return dclone $active;
}

# this deref also happens a lot
sub GetActiveList( $self ) {
  return( sort( keys( $self->Active->%* ) ) );
}


sub VotesCast ( $self ) {
  return $self->BallotSet()->{'votescast'};
}

sub VotesActive ( $self ) {
  unless ( $self->BallotSet()->{'options'}{'rcv'} ) {
    die "VotesActive Method only supports rcv"
  }
  my $set         = $self->BallotSet();
  my $active      = $self->Active();
  my $activeCount = 0;
LOOPVOTESACTIVE:
    for my $B ( values $set->{ballots}->%* ) {
        for my $V ( $B->{'votes'}->@* ) {
            if ( defined $active->{$V} ) {
                $activeCount += $B->{'count'};
                next LOOPVOTESACTIVE;
            }
        }
    }
  return $activeCount;
}

sub BallotSetType ( $self ) {
  if ( $self->BallotSet()->{'options'}{'rcv'} ) {
    return 'rcv';
  }
  elsif ( $self->BallotSet()->{'options'}{'range'} ) {
    return 'range';
  }
  else {
    die "BallotSetType is undefined or unknown type.";
  }
}

1;


=head2 Usage

This role is consumed by Vote::Count and Vote::Count::Matrix.

=head3 new


=head3 Active

Get Active Set as HashRef to the active set. Changing the new HashRef will change the internal Active Set, GetActive is recommended as it will return a HashRef that is a copy instead.


=head3 GetActive

Returns a hashref containing a copy of the Active Set.


=head3 GetActiveList

Returns a simple array of the members of the Active Set.


=head3 ResetActive

Sets the Active Set to the full choices list of the BallotSet.


=head3 SetActive

Sets the Active Set to provided HashRef. The values to the hashref should evaluate as True.


=head3 SetActiveFromArrayRef

Same as SetActive except it takes an ArrayRef of the choices to be set as Active.


=head3 BallotSet

Get BallotSet


=head3 PairMatrix

Get a Matrix Object for the Active Set. Generated and cached on the first request.


=head3 UpdatePairMatrix

Regenerate and cache Matrix with current Active Set. 


=head3 VotesCast

Returns the number of votes cast.


=head3 VotesActive

Returns the number of non-exhausted ballots based on the current Active Set.

#FOOTER

=pod

BUG TRACKER

L<https://github.com/brainbuz/Vote-Count/issues>

AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

CONTRIBUTORS

Copyright 2019 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

=cut
