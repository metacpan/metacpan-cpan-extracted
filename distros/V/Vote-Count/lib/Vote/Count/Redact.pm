package Vote::Count::Redact;

use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;
use Storable 3.15 qw(dclone);

use namespace::autoclean;

# use Data::Printer;

no warnings 'experimental';

our $VERSION='0.017';

=head1 NAME

Vote::Count::Redact

=head1 VERSION 0.017

Methods for Redacting Ballots.

=head2 Purpose

Redacting Ballots is useful for what-if analysis and identifying Later Harm effects. Compound Methods seeking to reduce Later Harm effects can also be developed using this technique.

  use Vote::Count::Redact qw/RedactPair RedactBullet RedactSingle/;

=cut



# ABSTRACT: Methods for Redacting Vote::Count BallotSets.

use Exporter::Easy (
       OK => [ qw( RedactSingle RedactPair RedactBullet ) ],
   );

=head2 RedactBullet

Takes a list (array) of choices to be converted to bullet votes. Returns a modified BallotSet where all votes that had a first choice vote for a member of the list are votes for only that choice.

  my $newBallotSet = RedactBullet( $VoteCountObject->BallotSet(), 'A', 'B', 'F');

=cut

sub RedactBullet ( $ballotset, @choices ) {
  my $new     = dclone($ballotset);
  my %ballots = $new->{'ballots'}->%*;
REDACTBULLETLOOP:
  for my $ballot ( keys %ballots ) {
    my @newvote = ();
    my $oldvote = $ballots{$ballot}->{'votes'}[0];
    if ( grep( /^$oldvote$/, @choices ) ) {
      $ballots{$ballot}->{'votes'} = [$oldvote];
    }
  }
  $new->{'ballots'} = \%ballots;
  return $new;
}

=head2 RedactSingle

Return a new BallotSet truncating the ballots after the given choice.

  my $newBallotSet = RedactSingle( $VoteCountObject->BallotSet(), $choice);

=cut

sub RedactSingle( $ballotset, $A ) {
  my $new     = dclone($ballotset);
  my %ballots = $new->{'ballots'}->%*;
REDACTSINGLELOOP:
  for my $ballot ( keys %ballots ) {
    my @newvote = ();
    my @oldvote = $ballots{$ballot}{'votes'}->@*;
    while (@oldvote) {
      my $v = shift @oldvote;
      push @newvote, $v;
      if ( $v eq $A ) { @oldvote = () }
      else { }
      $ballots{$ballot}{'votes'} = \@newvote;
    }
    $ballots{$ballot}{'votes'} = \@newvote;
  }
  $new->{'ballots'} = \%ballots;
  return $new;
}

=head2 RedactPair

For a Ballot Set and two choices, on each ballot where both appear it removes the later one, returning a completely independent new BallotSet.

  my $newBallotSet = RedactPair( $VoteCountObject->BallotSet(), 'A', 'B');

=cut

# RedactPair only alters votes involving the two choices
# The other two methods truncate after the choice.

sub RedactPair ( $ballotset, $A, $B ) {
  my $new     = dclone($ballotset);
  my %ballots = $new->{'ballots'}->%*;
REDACTPAIRLOOP:
  for my $ballot ( keys %ballots ) {
    my @newvote = ();
    my @oldvote = $ballots{$ballot}{'votes'}->@*;
    while (@oldvote) {
      my $v = shift @oldvote;
      push @newvote, $v;
      if ( $v eq $A ) {
        while (@oldvote) {
          my $u = shift @oldvote;
          push @newvote, ($u) unless $u eq $B;
        }
      }
      elsif ( $v eq $B ) {
        while (@oldvote) {
          my $u = shift @oldvote;
          push @newvote, ($u) unless $u eq $A;
        }
      }
      else { }
      $ballots{$ballot}{'votes'} = \@newvote;
    }
  }
  $new->{'ballots'} = \%ballots;
  return $new;
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

