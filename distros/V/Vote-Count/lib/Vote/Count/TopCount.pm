use strict;
use warnings;
use 5.022;

use feature qw /postderef signatures/;

package Vote::Count::TopCount;
use Moose::Role;

no warnings 'experimental';
use List::Util qw( min max );
use Vote::Count::RankCount;
use Vote::Count::TextTableTiny 'generate_markdown_table';

use Math::BigRat try => 'GMP';
use Storable 'dclone';

# ABSTRACT: TopCount and related methods for Vote::Count. Toolkit for vote counting.

our $VERSION='1.08';

=head1 NAME

Vote::Count::TopCount

=head1 VERSION 1.08

=head1 Synopsis

This Role is consumed by Vote::Count it provides TopCount and related Methods to Vote::Count objects.

=head2 Definition of Top Count

Top Count is tabulation of the Top Choice vote on each ballot. As choices are eliminated the first choice on some ballots will be removed, the next highest remaining choice becomes the Top Choice for that ballot. When all choices on a ballot are eliminated it becomes exhausted and is no longer counted.

=head2 Method TopCount

Takes a hashref of active choices as an optional parameter, if one is not provided it uses the internal active list accessible via the ->Active() method, which itself defaults to the BallotSet's Choices list.

Returns a RankCount object containing the TopCount.

TopCount supports both Ranked and Range Ballot Types.

=head3 Top Counting Range Ballots

Since Range Ballots often allow ranking choices equally, those equal votes need to be split. To prevent Rounding errors in the addition on large sets the fractions are added as Rational Numbers. The totals are converted to floating point numbers with a precision of 3 places. Three was arbitrarily chosen because it is reasonable for display, but precise enough as a truncation point to be unlikely to cause an error.

It is recommended to install Math::BigInt::GMP to improve performance on the Rational Number math used for Top Count on Range Ballots.

=cut

sub _RangeTopCount ( $self, $active = undef ) {
  $active = $self->Active() unless defined $active;
  my %topcount = ( map { $_ => Math::BigRat->new(0) } keys( $active->%* ) );
TOPCOUNTRANGEBALLOTS:
  for my $b ( $self->BallotSet()->{'ballots'}->@* ) {
    my $vv    = dclone $b->{'votes'};
    my %votes = $vv->%*;
    for my $v ( keys %votes ) {
      delete $votes{$v} unless defined $active->{$v};
    }
    next TOPCOUNTRANGEBALLOTS unless keys %votes;
    my $max = max( values %votes );
    my @top = ();
    for my $c ( keys %votes ) {
      if ( $votes{$c} == $max ) { push @top, $c }
    }
    my $topvalue = Math::BigRat->new( $b->{'count'} / scalar(@top) );
    for (@top) { $topcount{$_} += $topvalue }
  }
  for my $k ( keys %topcount ) {
    $topcount{$k} = $topcount{$k}->as_float(3)->numify();
  }
  return Vote::Count::RankCount->Rank( \%topcount );
}

sub _RCVTopCount ( $self, $active = undef ) {
  my %ballotset = $self->BallotSet()->%*;
  my %ballots   = ( $ballotset{'ballots'}->%* );
  $active = $self->Active() unless defined $active;
  my %topcount = ( map { $_ => 0 } keys( $active->%* ) );
TOPCOUNTBALLOTS:
  for my $b ( keys %ballots ) {
    my @votes = $ballots{$b}->{'votes'}->@*;
    for my $v (@votes) {
      if ( defined $topcount{$v} ) {
        $topcount{$v} += $ballots{$b}{'count'};
        next TOPCOUNTBALLOTS;
      }
    }
  }
  return Vote::Count::RankCount->Rank( \%topcount );
}

sub TopCount ( $self, $active = undef ) {
  if ( $self->BallotSet()->{'options'}{'rcv'} == 1 ) {
    return $self->_RCVTopCount($active);
  }
  elsif ( $self->BallotSet()->{'options'}{'range'} == 1 ) {
    return $self->_RangeTopCount($active);
  }
}

=head2 Method TopCountMajority

  $self->TopCountMajority( $round_topcount )
  or
  $self->TopCountMajority( undef, $active_choices )

Will find the majority winner from the results of a topcount, or alternately may be given undef and a hashref of active choices and will topcount the ballotset for just those choices and then find the majority winner.

Returns a hashref of results. It will always include the votes in the round and the threshold for majority. If there is a winner it will also include the winner and winvotes.

=cut

sub TopCountMajority ( $self, $topcount = undef, $active = undef ) {
  $active = $self->Active() unless defined $active;
  unless ( defined $topcount ) { $topcount = $self->TopCount($active) }
  my $topc      = $topcount->RawCount();
  my $numvotes  = $topcount->CountVotes();
  my @choices   = keys $topc->%*;
  my $threshold = 1 + int( $numvotes / 2 );
  for my $t (@choices) {
    if ( $topc->{$t} >= $threshold ) {
      return (
        {
          votes     => $numvotes,
          threshold => $threshold,
          winner    => $t,
          winvotes  => $topc->{$t}
        }
      );
    }
  }
  # No winner
  return (
    {
      votes     => $numvotes,
      threshold => $threshold,
    }
  );
}

=head2 Method EvaluateTopCountMajority

This method wraps TopCountMajority adding logging, the logging of which would be a lot of boiler plate in round oriented methods. It takes the same parameters and returns the same hashref.

=cut

sub EvaluateTopCountMajority ( $self, $topcount = undef, $active = undef ) {
  my $majority = $self->TopCountMajority( $topcount, $active );
  if ( $majority->{'winner'} ) {
    my $winner = $majority->{'winner'};
    my $rows   = [
      [ 'Winner',                    $winner ],
      [ 'Votes in Final Round',      $majority->{'votes'} ],
      [ 'Votes Needed for Majority', $majority->{'threshold'} ],
      [ 'Winning Votes',             $majority->{'winvotes'} ],
    ];
    $self->logt(
      '---',
      generate_markdown_table(
        rows       => $rows,
        header_row => 0
      )
    );
  }
  return $majority;
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
