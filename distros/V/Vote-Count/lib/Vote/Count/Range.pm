use strict;
use warnings;
use 5.022;

use feature qw /postderef signatures/;

package Vote::Count::Range;
use Moose::Role;

no warnings 'experimental';
use Data::Printer;

our $VERSION='0.00';

sub RangeBallotPair ( $self, $A, $B ) {
  my $countA   = 0;
  my $countB   = 0;
  my $approval = $self->Approval();
  for my $ballot ( $self->BallotSet()->{'ballots'}->@* ) {
    my $prefA = $ballot->{'votes'}{$A} || 0;
    my $prefB = $ballot->{'votes'}{$B} || 0;
    if    ( $prefA > $prefB ) { $countA += $ballot->{'count'} }
    elsif ( $prefA < $prefB ) { $countB += $ballot->{'count'} }
    else                      { }
  }
  return ( $countA, $countB );
}

1;

