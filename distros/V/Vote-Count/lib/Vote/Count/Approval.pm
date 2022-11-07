use strict;
use warnings;
use 5.024;

use feature qw /postderef signatures/;

package Vote::Count::Approval;
use Moose::Role;

no warnings 'experimental';
use Carp;

our $VERSION='2.02';

=head1 NAME

Vote::Count::Approval

=head1 VERSION 2.02

=cut

# ABSTRACT: Approval for Vote::Count. Toolkit for vote counting.

=head1 Definition of Approval

In Approval Voting, voters indicate which Choices they approve of indicating no preference. Approval can be infered from a Ranked Choice Ballot, by treating each ranked Choice as Approved.

=head1 Method Approval

Returns a RankCount object for the current Active Set taking an optional argument of an active list as a HashRef.

  my $Approval = $Election->Approval();
  say $Approval->RankTable;

  # to specify the active set
  my $Approval = $Election->Approval( $activeset );

  # to specify a cutoff on Range Ballots
  my $Approval = $Election->Approval( $activeset, $cutoff );

For RCV, Approval respects weighting, 'votevalue' is defaulted to 1 by readballots. Integers or Floating point values may be used.

=head2 Method LastApprovalBallots

Returns a hashref of the unweighted raw count from the last Approval operation.

=head2 Method NonApproval

The opposite of Approval. Returns a RankCount object for the current Active Set of the non-exhausted ballots not supporting a choice. It does not have the option to provide an Active Set. Only available for Ranked Ballots.

=head3 Cutoff (Range Ballots Only)

When counting Approval on Range Ballots an optional cutoff value may be provided as a second argument to the Approval Method. When doing so the Active Set argument must be provided. The Cutoff value is a score below which the ballot is considered to not approve of the choice.

When counting Approval on Range Ballots it is appropriate to set a threshold below which a choice is not considered to be supported by the voter, but indicated to represent a preference to even lower or unranked choices.

For Ranked Ballots the equivalent would be to provide a 'Nuetral Preference', for voters to indicate that any choices ranked lower should not be considered approved. This is not presently implemented, but may be at some point in the future.

=cut

has 'LastApprovalBallots' => (
  is => 'rw',
  isa     => 'HashRef',
  required => 0,
);

sub _approval_rcv_do ( $I, $active, $ballots ) {
  my %approval = ( map { $_ => 0 } keys( $active->%* ) );
  my %lastappcount = ( map { $_ => 0 } keys( $active->%* ) );
  for my $b ( keys %{$ballots} ) {
    my @votes = $ballots->{$b}->{'votes'}->@*;
    for my $v (@votes) {
      if ( defined $approval{$v} ) {
        $approval{$v} += $ballots->{$b}{'count'} * $ballots->{$b}{'votevalue'} ;
        $lastappcount{$v} += $ballots->{$b}{'count'};
      }
    }
  }
  $I->LastApprovalBallots( \%lastappcount );
  return Vote::Count::RankCount->Rank( \%approval );
}

sub _approval_range_do ( $active, $ballots, $cutoff ) {
  my %approval = ( map { $_ => 0 } keys( $active->%* ) );
  for my $b ( @{$ballots} ) {
  APPROVALKEYSC: for my $c ( keys $b->{'votes'}->%* ) {
      # croak "key is $c " . "value is $b->{'votes'}{$c}";
      next APPROVALKEYSC if $b->{'votes'}{$c} < $cutoff;
      $approval{$c} += $b->{'count'} if defined $approval{$c};
    }
  }
  return Vote::Count::RankCount->Rank( \%approval );
}

sub Approval ( $self, $active = undef, $cutoff = 0 ) {
  my %BallotSet = $self->BallotSet()->%*;
  $active = $self->Active() unless defined $active;
  if ( $BallotSet{'options'}{'range'} ) {
    return _approval_range_do( $active, $BallotSet{'ballots'},
      $cutoff );
  }
  else {
    $self->_approval_rcv_do( $active, $BallotSet{'ballots'} );
  }
}

sub approval { Approval(@_) }

sub _non_approval_rcv_do ( $I, $ballots ) {
  my $active = $I->Active();
  my %nonapproval = ( map { $_ => 0 } keys( $active->%* ) );
  my %approval = %{$I->_approval_rcv_do ( $active, $ballots )->RawCount()};
  my $activevotes = $I->VotesActive();
  for my $A ( keys %nonapproval) {
    $nonapproval{ $A } = $activevotes - $approval{ $A };
  }
  return Vote::Count::RankCount->Rank( \%nonapproval );
}

# For each choice in the active set counts ballots
sub NonApproval ( $I, $cutoff = 0 ) {
  my %BallotSet = $I->BallotSet()->%*;
  my $ballots = $BallotSet{'ballots'};
  if ( $BallotSet{'options'}{'rcv'} ) {
    return _non_approval_rcv_do( $I, $ballots );
  }
  else {
    die "NonApproval currently implemented for RCV ballots."
  }
}

1;

#FOOTER

=pod

BUG TRACKER

L<https://github.com/brainbuz/Vote-Count/issues>

AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

CONTRIBUTORS

Copyright 2019-2021 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

SUPPORT

This software is provided as is, per the terms of the GNU Public License. Professional support and customisation services are available from the author.

=cut

