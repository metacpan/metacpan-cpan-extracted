use strict;
use warnings;
use 5.022;

use feature qw /postderef signatures/;

package Vote::Count::Approval;
use Moose::Role;

no warnings 'experimental';
use Carp;

our $VERSION='1.07';

=head1 NAME

Vote::Count::Approval

=head1 VERSION 1.07

=cut

# ABSTRACT: Approval for Vote::Count. Toolkit for vote counting.

=head1 Definition of Approval

In Approval Voting, voters indicate which Choices they approve of indicating no preference. Approval can be infered from a Ranked Choice Ballot, by treating each ranked Choice as Approved.

=head1 Method Approval

Returns a RankCount object for the current Active Set taking an optional argument of an active list as a HashRef.

  my $Approval = $Election->Approval();
  say $Approval->RankTable;

  # to specify the activeset
  my $Approval = $Election->Approval( $activeset );

  # to specify a cutoff on Range Ballots
  my $Approval = $Election->Approval( $activeset, $cutoff );

=head1 Method NonApproval  

The opposite of Approval. Returns a RankCount object for the current Active Set of the non-exhausted ballots not supporting a choice. It does not have the option to provide an Active Set. Only available for Ranked Ballots. 

=head2 Cut Off (Range Ballots Only)

When counting Approval on Range Ballots it is appropriate to set a threshold below which a choice is not considered to be supported by the voter, but indicated to represent a preference to even lower or unranked choices. 

A good value is half of the maximum possible score, however, the default action must be to treat all choices with a score as approved. With a Range of 0-10 a cutoff of 5 would be recommended, choices scored 4 or lower would not be counted for approval. If cutoff isn't provided it defaults to 0 producing the desired default behaviour.

For Ranked Ballots the cutoff is ignored. If a cutoff is desired for Ranked Ballots a Neutral Preference Option should be included on the Ballot to indicate when subequent choices should not be considered Approved. This is not currently available in Vote::Count.

=cut

sub _approval_rcv_do ( $active, $ballots ) {
  my %approval = ( map { $_ => 0 } keys( $active->%* ) );
  for my $b ( keys %{$ballots} ) {
    my @votes = $ballots->{$b}->{'votes'}->@*;
    for my $v (@votes) {
      if ( defined $approval{$v} ) {
        $approval{$v} += $ballots->{$b}{'count'};
      }
    }
  }
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
    _approval_rcv_do( $active, $BallotSet{'ballots'} );
  }
}

sub _non_approval_rcv_do ( $I, $ballots ) {
  my $active = $I->Active();
  my %nonapproval = ( map { $_ => 0 } keys( $active->%* ) );
  my %approval = %{_approval_rcv_do ( $active, $ballots )->RawCount()};
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

Copyright 2019 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

=cut
