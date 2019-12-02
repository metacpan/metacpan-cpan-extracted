use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Score;

use Moose::Role;

# use Storable 3.15 qw(dclone);
# use Try::Tiny;

our $VERSION='1.00';

=head1 NAME

Vote::Count::Score

=head1 VERSION 1.00

=cut

# ABSTRACT: Provides Score Method for Range Ballots to Vote::Count objects

no warnings 'experimental';
use Vote::Count::RankCount;
# use Try::Tiny;
# use boolean;
# use Data::Printer;

=pod

=head1 Synopsis

  my $RangeElection = Vote::Count->new(
    BallotSet  => read_range_ballots('t/data/tennessee.range.json')
    );
  my $scored = $RangeElection->Score();

=head1 Score

When Range (Cardinal) Ballots are used, it is simple and obvious to total the scores provided by the voters. This contrasts to the related Borda Method which assigns scores based on position on a Ranked Ballot.

=head1 Method Score

Returns a RankCount Object with the choices scored using the scores set by the voters, for Range Ballots.

=cut

sub Score ( $self, $active = undef ) {
  my $depth = $self->BallotSet()->{'depth'};
  # my @Ballots = $self->BallotSet()->{'ballots'}->@*;
  $active = $self->Active() unless defined $active;
  my %scores = ( map { $_ => 0 } keys( $active->%* ) );
  for my $ballot ( $self->BallotSet()->{'ballots'}->@* ) {
    for my $choice ( keys %scores ) {
      if ( defined $ballot->{'votes'}{$choice} ) {
        $scores{$choice} += $ballot->{'count'} * $ballot->{'votes'}{$choice};
      }
    }
  }
  return Vote::Count::RankCount->Rank( \%scores );
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
