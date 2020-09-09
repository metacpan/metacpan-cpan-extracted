use strict;
use warnings;
use 5.022;

package Vote::Count::RankCount;

use feature qw /postderef signatures/;
no warnings 'experimental';
use List::Util qw( min max sum);
use Vote::Count::TextTableTiny qw/generate_markdown_table/;
use Sort::Hash;

our $VERSION='1.08';

=head1 NAME

Vote::Count::RankCount

=head1 VERSION 1.08

=cut

# ABSTRACT: RankCount object for Vote::Count. Toolkit for vote counting.

sub _RankResult ( $rawcount ) {
  my %rc      = ( $rawcount->%* );  # destructive process needs to use a copy.
  my %ordered = ();
  my %byrank  = ();
  my $pos     = 0;
  my $maxpos  = scalar( keys %rc );
  while ( 0 < scalar( keys %rc ) ) {
    $pos++;
    my @vrc = values %rc;
    my $max = max @vrc;
    for my $k ( keys %rc ) {
      if ( $rc{$k} == $max ) {
        $ordered{$k} = $pos;
        delete $rc{$k};
        if ( defined $byrank{$pos} ) {
          push @{ $byrank{$pos} }, $k;
        }
        else {
          $byrank{$pos} = [$k];
        }
      }
    }
    die "Vote::Count::RankCount::Rank in infinite loop\n"
      if $pos > $maxpos;
  }
  # %byrank[1] is arrayref of 1st position,
  # $pos still has last position filled, %byrank{$pos} is the last place.
  # sometimes byranks came in as var{byrank...} deref and reref fixes this
  # although it would be better if I understood why it happened.
  # It is useful to sort the arrays anyway, for display they would likely be
  # sorted anyway. For testing it makes the element order predictable.

  for my $O ( keys %byrank ) {
    $byrank{$O} = [ sort $byrank{$O}->@* ];
  }
  my @top    = @{ $byrank{1} };
  my @bottom = @{ $byrank{$pos} };
  my $tie    = scalar(@top) > 1 ? 1 : 0;
  return {
    'rawcount' => $rawcount,
    'ordered'  => \%ordered,
    'byrank'   => \%byrank,
    'top'      => \@top,
    'bottom'   => \@bottom,
    'tie'      => $tie,
  };
}

=head1 Rank

Takes a single argument of a hashref containing Choices as Keys and Votes as Values. Returns an Object. This method is also aliased as new.

=cut

sub Rank ( $class, $rawcount ) {
  my $I = _RankResult($rawcount);
  return bless $I, $class;
}

sub new ( $class, $rawcount ) {
  my $I = _RankResult($rawcount);
  return bless $I, $class;
}

=head2 Methods

=over

=item * RawCount

Returns the original HashRef used for Object Creation.

=item * HashWithOrder

Returns a HashRef with the Choices as Keys and the position of the choice, the value for the Leader would be 1 and the Third Place Choice would be 3.

=item * HashByRank

Returns a HashRef where the keys are numbers and the values an ArrayRef of the Choices in that position. The ArrayRefs are sorted alphanumerically.

=item * ArrayTop, ArrayBottom

Returns an ArrayRef of the Choices in the Top or Bottom Positions.

=item * CountVotes

Returns the number of votes in the RawCount. This is not the same as the votes in the BallotSet from which that was derived. For TopCount it is the number of non-exhausted ballots in the round that generated RawCount, for Approval and Boorda it is probably not useful.

=item * Leader

Returns a HashRef with the keys tie, tied, winner where winner is the winner, tie is true or false and tied is an array ref of the choices in the tie.

=back

=head3 RankTable

Generates a MarkDown formatted table.

=cut

sub RawCount ( $I )      { return $I->{'rawcount'} }
sub HashWithOrder ( $I ) { return $I->{'ordered'} }
sub HashByRank ( $I )    { return $I->{'byrank'} }
sub ArrayTop ( $I )      { return $I->{'top'} }
sub ArrayBottom ( $I )   { return $I->{'bottom'} }
sub CountVotes ($I)      { return sum( values $I->{'rawcount'}->%* ) }

sub Leader ( $I ) {
  my @leaders = $I->ArrayTop()->@*;
  my %return = ( 'tie' => 0, 'winner' => '', 'tied' => [] );
  if ( 1 == @leaders ) { $return{'winner'} = $leaders[0] }
  elsif ( 1 < @leaders ) { $return{'tie'} = 1; $return{'tied'} = \@leaders }
  else                   { die "Does not compute in sub RankCount->Leader\n" }
  return \%return;
}

sub RankTable( $self ) {
  my @rows   = ( [ 'Rank', 'Choice', 'Votes' ] );
  my %rc     = $self->{'rawcount'}->%*;
  my %byrank = $self->{'byrank'}->%*;
  for my $r ( sort { $a <=> $b } ( keys %byrank ) ) {
    my @choice = sort $byrank{$r}->@*;
    for my $choice (@choice) {
      my $votes = $rc{$choice};
      my @row = ( $r, $choice, $votes );
      push @rows, ( \@row );
    }
  }
  return generate_markdown_table( rows => \@rows ) . "\n";
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

