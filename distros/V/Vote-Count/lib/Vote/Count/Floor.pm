use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Floor;
use namespace::autoclean;
use Moose::Role;
# use Data::Dumper;

no warnings 'experimental';

our $VERSION = '1.10';

=head1 NAME

Vote::Count::Floor

=head1 VERSION 1.10

=cut

# ABSTRACT: Floor Rules for RCV elections.

# load the roles providing the underlying ops.
with 'Vote::Count::Approval', 'Vote::Count::TopCount',;

has 'FloorRounding' => (
  is      => 'rw',
  isa     => 'Str',
  default => 'up'
);

sub _FloorRnd ( $I, $num ) {
  if ( $I->FloorRounding eq 'down' ) {
    return int($num);
  }
  elsif ( $I->FloorRounding eq 'up' ) {
    return int($num) if ( $num == int($num) );
    return int( $num + 1 );
  }
  elsif ( $I->FloorRounding eq 'round' ) {
    return int( $num + 0.5 );
  }
  elsif ( $I->FloorRounding eq 'nextint' ) {
    return int( $num + 1 );
  }
  else { die 'unknown FloorRounding method requested: ' . $I->FloorRounding }
}

sub _FloorMin ( $I, $floorpct ) {
  my $pct = $floorpct >= 1 ? $floorpct / 100 : $floorpct;
  return $I->_FloorRnd( $I->VotesCast() * $pct );
}

sub _DoFloor ( $I, $ranked, $cutoff ) {
  my @active = ();
  my @remove = ();
  for my $s ( keys $ranked->%* ) {
    if ( $ranked->{$s} >= $cutoff ) { push @active, $s }
    else {
      push @remove, $s;
      $I->logv("Removing: $s: $ranked->{$s}, minimum is $cutoff.");
    }
  }
  if (@remove) {
    $I->logt(
      "Floor Rule Eliminated: ",
      join( ', ', @remove ),
      "Remaining: ", join( ', ', @active ),
    );
  }
  else {
    $I->logt('None Eliminated');
  }
  return { map { $_ => 1 } @active };
}

# Approval Floor is Approval votes vs total
# votes cast -- not total of approval votes.
sub ApprovalFloor ( $self, $floorpct = 5, $rangecutoff = 0 ) {
  my $votescast = $self->VotesCast();
  $self->logt( "Applying Floor Rule of $floorpct\% "
      . "Approval Count. vs Ballots Cast of $votescast." );
  my $raw =
    $self->BallotSetType() eq 'rcv'
    ? do { $self->Approval(); $self->LastApprovalBallots() }
    : $self->Approval( undef, $rangecutoff )->RawCount();
  return $self->_DoFloor( $raw, $self->_FloorMin($floorpct) );
}

sub TopCountFloor ( $self, $floorpct = 2 ) {
  $self->logt("Applying Floor Rule of $floorpct\% First Choice Votes.");
  my $raw =
    $self->BallotSetType() eq 'rcv'
    ? do { $self->TopCount(); $self->LastTopCountUnWeighted() }
    : $self->TopCount();
  return $self->_DoFloor( $raw, $self->_FloorMin($floorpct) );
}

sub TCA ( $self, $floor = .5 ) {
  if ( $floor > 1 ) {
    my $m = "Floor value $floor is greater than 1";
    $self->logt($m);
    die "$m\n";
  }
  $self->logt(
    'Applying Floor Rule: Approval Must at least ',
    "$floor times the Most First Choice votes. "
  );
  my $tc = $self->TopCount();
  # arraytop returns a list in case of tie.
  my $winner = shift( $tc->ArrayTop->@* );
  my $tcraw  = $tc->RawCount()->{$winner};
  my $cutoff = $self->_FloorRnd( $tcraw * $floor );
  $self->logv( "The most first choice votes for any choice is $tcraw.",
    "Cutoff will be $cutoff" );
  return $self->_DoFloor( $self->Approval()->RawCount(), $cutoff );
}

sub ApplyFloor ( $self, $rule, @args ) {
  my $newset = {};
  if ( $rule eq 'ApprovalFloor' ) {
    $newset = $self->ApprovalFloor(@args);
  }
  elsif ( $rule eq 'TopCountFloor' ) {
    $newset = $self->TopCountFloor(@args);
  }
  elsif ( $rule eq 'TCA' ) {
    $newset = $self->TCA(@args);
  }
  else {
    die "Bad rule provided to ApplyFloor, $rule";
  }
  $self->SetActive($newset);
  return $newset;
}

=head1 Floor Rules

In real elections it is common to have choices with very little support, with write-ins there can be a large number of these choices, with iterative dropping like IRV it can take many rounds to work through them. A Floor Rule sets a criteria to remove the weakly supported choices early in a single operation.

=head1 SYNOPSIS

  my $Election = Vote::Count->new( BallotSet => $someballotset );
  my $ChoicesAfterFloor = $Election->ApprovalFloor();
  $Election->SetActive( $ChoicesAfterFloor ); # To apply the floor
  $Election->ApplyFloor( 'TopCountFloor', @options ); # One Step

=head1 Rounding

The default rounding is up. If a calculated cutoff is 11.2, the cutoff will become greater than or equal to 12. Set FloorRounding to 'down' to change this to round down for 11.9 to become 11. Set FloorRounding to 'round' to change this to round .5 or greater up. If the comparison needs to be Greater than, a FloorRounding of 'nextint' will use the next higher integer.

  # When creating the Election.
  my $Election = Vote::Count->new( FloorRounding => 'round', ... );
  # Before applying the floor.
  $Election->FloorRounding( 'down');

=head1 The Floor Methods

All Methods in this Module apply a floor rule, log the eliminations and return the set of remaining choices as a HashRef. Use the ApplyFloor Method to immediately apply the results.

=head2 ApplyFloor

Takes as an argument the Method Name as a string of the rule to apply ( ApprovalFloor, TopCountFloor, TCA), followed by any optional arguments for the rule. Sets the Active Set as defined by that rule and returns the new Active Set as a hashref.

  # Apply a TopCount Floor of 10%.
  my $newactive = $Election->ApplyFloor( 'TopCountFloor', 10);

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

This rule takes an optional argument to change the floor from .5.

  # uses default of 1/2
  my $active = $Election->TCA();
  # requires approval equal leader
  my $active = $Election->TCA( 1 );

=head3 TCA Rule Validation and Implication

If there is a Loop or Condorcet Winner, either it will be/include the Top Count Leader or it must be a choice which defeats the Top Count leader. To defeat the Top Count Leader a Choice's Approval must be greater than the Lead Top Count. To be able to defeat a choice it is necessary to have more than half of the approval of that choice. Thus to be able to defeat a choice which can defeat the Top Count Leader it will be necessary to have more than half of the Approval of a choice with an Approval greater than the lead Top Count.

There is a small possibility for a situation with a deeply nested knotted result that this rule could eliminate a member of the Dominant Set. For the common simple dropping rules (Approval, Top Count, Greatest Loss, Borda) this choice would never win.

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
