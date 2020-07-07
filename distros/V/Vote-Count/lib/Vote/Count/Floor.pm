use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Floor;
use namespace::autoclean;
use Moose::Role;

# use Data::Printer;

no warnings 'experimental';

our $VERSION='1.05';

=head1 NAME

Vote::Count::Floor

=head1 VERSION 1.05

=cut

# ABSTRACT: Floor Rules for RCV elections.

# load the roles providing the underlying ops.
with 'Vote::Count::Approval', 'Vote::Count::TopCount',;

sub _FloorMin ( $self, $floorpct ) {
  my $pct = $floorpct >= 1 ? $floorpct / 100 : $floorpct;
  return int( $self->VotesCast() * $pct );
}

sub _DoFloor ( $self, $ranked, $cutoff ) {
  my @active = ();
  my @remove = ();
  for my $s ( keys $ranked->%* ) {
    if ( $ranked->{$s} >= $cutoff ) { push @active, $s }
    else {
      push @remove, $s;
      $self->logv("Removing: $s: $ranked->{$s}, minimum is $cutoff.");
    }
  }
  $self->logt(
    "Floor Rule Eliminated: ",
    join( ', ', @remove ),
    "Remaining: ", join( ', ', @active ),
  );
  return { map { $_ => 1 } @active };
}

# Approval Floor is Approval votes vs total
# votes cast -- not total of approval votes.
# so floor is the same as for topcount floor.
sub ApprovalFloor ( $self, $floorpct = 5, $rangecutoff = 0 ) {
  my $votescast = $self->VotesCast();
  $self->logt( "Applying Floor Rule of $floorpct\% "
      . "Approval Count. vs Ballots Cast of $votescast." );
  return $self->_DoFloor( $self->Approval( undef, $rangecutoff )->RawCount(),
    $self->_FloorMin($floorpct) );
}

sub TopCountFloor ( $self, $floorpct = 2 ) {
  $self->logt("Applying Floor Rule of $floorpct\% First Choice Votes.");
  return $self->_DoFloor( $self->TopCount()->RawCount(),
    $self->_FloorMin($floorpct) );
}

sub TCA( $self ) {
  $self->logt(
    'Applying Floor Rule: Approval Must be at least ',
    '50% of the Most First Choice votes for any Choice.'
  );
  my $tc = $self->TopCount();
  # arraytop returns a list in case of tie.
  my $winner = shift( $tc->ArrayTop->@* );
  my $tcraw  = $tc->RawCount()->{$winner};
  my $cutoff = int( $tcraw / 2 );
  $self->logv( "The most first choice votes for any choice is $tcraw.",
    "Cutoff will be $cutoff" );
  my $ac = $self->Approval()->RawCount();
  return $self->_DoFloor( $self->Approval()->RawCount(), $cutoff );
}

=head1 Floor Rules

In real elections it is common to have choices with very little support, the right to write-in and the obligation to count write-ins can produce a large number of these choices, with iterative dropping like IRV it can take many rounds which have to be logged into the election report to work through them. A Floor Rule sets a criteria to remove the weakly supported choices early in a single operation. If you are implementing a Hand-Count compatible process having an aggressive Floor Rule can be a benefit.

=head1 SYNOPSIS

  my $Election = Vote::Count->new( BallotSet => $someballotset );
  my $ChoicesAfterFloor = $Election->ApprovalFloor();
  $Election->Active( $ChoicesAfterFloor ); # To apply the floor

=head1 The Floor Methods

All Methods in this Module apply a floor rule, log the eliminations and return the set of remaining choices as an Active Set. They do not set the Election's active set, since it is possible that this isn't the desired action.

=head2 ApprovalFloor, TopCountFloor

Requires a percent of votes cast in Approval or TopCount. The default is 5% for Approval and 2% for TopCount.

  # TopCountFloor with 3% threshold.
  my $Floored = $Election->TopCountFloor( 3 );

Both of these methods take an optional parameter which is the percentage for the floor. If the parameter is 1 or greater the parameter will be interpreted as a percentage, if it is less than 1 it will be interpreted as a decimal fraction, .1 and 10 will both result in a 10% floor.

For Range Ballots using ApprovalFloor there is an additional optional value for cutoff that sets the score below which choices are not considered approved of.

  # Applies 5% floor with cutoff 5 (appropriate for Range 0-10)
  my $active = $Range->ApprovalFloor( 5, 5 );

=head2 TCA (TopCount-Approval)

Aggressive but (effectively) safe for Condorcet Methods. It requires the Approval for a choice be at least half of the leading Top Count Vote.

This rule takes no optional arguments.

=head3 TCA Rule Validation and Implication

If there is a Loop or Condorcet Winner, either it will be/include the Top Count Leader or it must be a choice which defeats the Top Count leader. To defeat the Top Count Leader a Choice's Approval must be greater than the Lead Top Count. To be able to defeat a choice it is necessary to have more than half of the approval of that choice. Thus to be able to defeat a choice which can defeat the Top Count Leader it will be necessary to have more than half of the Approval of a choice with an Approval greater than the lead Top Count.

There is a small possibility for a situation with a deeply nested knotted result that this rule could eliminate a member of the Dominant Set. For the common simple dropping rules (Approval, Top Count, Greatest Loss, Borda)  this choice would never win.

For IRV any choice with an Approval that is not greater than the current TopCount of any other choice will always be eliminated prior to that choice. Unfortunately, with IRV any change to dropping order can alter the result. If it is used in IRV the Election Rules must specify it. Also because it is a high Approval based Floor, it can be construed as adding a small risk of Later Harm violation. If the reason for choosing IRV was Later Harm, then the only safe floor is a TopCount floor.

=cut

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
