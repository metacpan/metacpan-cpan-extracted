use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Matrix;
use Moose;

with 'Vote::Count::TieBreaker',
  'Vote::Count::Approval',
  'Vote::Count::Borda',
  'Vote::Count::Log',
  'Vote::Count::Score',
  ;

use Vote::Count::RankCount;

no warnings 'experimental';
use List::Util qw( min max sum );
use Vote::Count::TextTableTiny qw/generate_markdown_table/;
use Sort::Hash;

# use Try::Tiny;
#use Data::Printer;
#use Data::Dumper;

use YAML::XS;

our $VERSION='1.05';

=head1 NAME

Vote::Count::Matrix

=head1 VERSION 1.05

=cut

# ABSTRACT: Condorcet Win Loss Matrix

has BallotSet => (
  is       => 'ro',
  required => 1,
  isa      => 'HashRef',
);

has Active => (
  is      => 'rw',
  isa     => 'HashRef',
  builder => 'Vote::Count::Matrix::_buildActive',
  lazy    => 1,
);

has TieBreakMethod => (
  is       => 'rw',
  isa      => 'Str',
  required => 0,
  default  => 'none',
);

sub _buildActive ( $self ) {
  return $self->BallotSet->{'choices'};
}

sub _untie ( $I, $A, $B ) {
  my @untie = $I->TieBreaker( $I->TieBreakMethod(), $I->Active(), $A, $B );
  return $untie[0] if ( scalar(@untie) == 1 );
  return 0;
}

sub _pairwinner_rcv ( $ballots, $A, $B ) {
  my $countA = 0;
  my $countB = 0;
FORVOTES:
  for my $b ( keys $ballots->%* ) {
    for my $v ( values $ballots->{$b}{'votes'}->@* ) {
      if ( $v eq $A ) {
        $countA += $ballots->{$b}{'count'};
        next FORVOTES;
      }
      elsif ( $v eq $B ) {
        $countB += $ballots->{$b}{'count'};
        next FORVOTES;
      }
    }
  }    # FORVOTES
  return ( $countA, $countB );
}

sub _conduct_pair ( $I, $A, $B ) {
  my $ballots = $I->BallotSet()->{'ballots'};
  my $countA  = 0;
  my $countB  = 0;
  $I->logv("Pairing: $A vs $B");
  if ( $I->BallotSet()->{'options'}{'range'} ) {
    ( $countA, $countB ) = $I->RangeBallotPair( $A, $B );
  }
  else {
    ( $countA, $countB ) = _pairwinner_rcv( $ballots, $A, $B );
  }
  my %retval = (
    $A       => $countA,
    $B       => $countB,
    'tie'    => 0,
    'winner' => '',
    'loser'  => '',
    'margin' => abs( $countA - $countB )
  );
  my $diff = $countA - $countB;
  # 0 : $countA == $countB
  if ( $diff == 0 ) {
    my $untied = $I->_untie( $A, $B );
    if ($untied) {
      $diff = 1  if $untied eq $A;
      $diff = -1 if $untied eq $B;
    }
  }
  if ( $diff == 0 ) {
    $retval{'winner'} = '';
    $retval{'tie'}    = 1;
  }
  # $diff > 0 A won or won tiebreaker.
  elsif ( $diff > 0 ) {
    $retval{'winner'} = $A;
    $retval{'loser'}  = $B;
  }
  # $diff < 0 B won or won tiebreaker.
  elsif ( $diff < 0 ) {
    $retval{'winner'} = $B;
    $retval{'loser'}  = $A;
  }
  if ( $retval{'winner'} ) {
    $I->logv("Winner: $retval{'winner'} ($A: $countA $B: $countB)");
  }
  else { $I->logv("Tie $A: $countA $B: $countB") }
  return \%retval;
}

sub BUILD {
  my $self      = shift;
  my $results   = {};
  my $ballotset = $self->BallotSet();
  my @choices   = keys $self->Active()->%*;
  while ( scalar(@choices) ) {
    my $A = shift @choices;
    for my $B (@choices) {
      my $result = $self->_conduct_pair( $A, $B );
      # Each result has two hash keys so it can be found without
      # having to try twice or sort the names for a single key.
      $results->{$A}{$B} = $result;
      $results->{$B}{$A} = $result;
    }
  }
  $self->{'Matrix'} = $results;
  $self->logt( "# Matrix", $self->MatrixTable() );
  $self->logv( "# Pairing Results", $self->PairingVotesTable() );
}

sub ScoreMatrix ( $self ) {
  my $scores = {};
  my %active = $self->Active()->%*;
  for my $A ( keys %active ) {
    my $hasties = 0;
    $scores->{$A} = 0;
    for my $B ( keys %active ) {
      next if $B eq $A;
      if ( $A eq $self->{'Matrix'}{$A}{$B}{'winner'} ) { $scores->{$A}++ }
      if ( $self->{'Matrix'}{$A}{$B}{'tie'} ) { $hasties = .001 }
    }
    if ( $scores->{$A} == 0 ) { $scores->{$A} += $hasties }
  }
  return $scores;
}

# return the choice with fewest wins in matrix.
sub LeastWins ( $matrix ) {
  my @lowest   = ();
  my %scored   = $matrix->ScoreMatrix()->%*;
  my $lowscore = min( values %scored );
  for my $A ( keys %scored ) {
    if ( $scored{$A} == $lowscore ) {
      push @lowest, $A;
    }
  }
  return @lowest;
}

sub CondorcetLoser ( $self, $nowins = 0 ) {
  my $unfinished = 1;
  my $wordy      = "Removing Condorcet Losers\n";
  my @eliminated = ();
  my $loser      = sub ( $score ) {
    if   ($nowins) { return 1 if $score < 1 }
    else           { return 1 if $score == 0 }
    return 0;
  };
CONDORCETLOSERLOOP:
  while ($unfinished) {
    $unfinished = 0;
    my $scores = $self->ScoreMatrix;
    my @alist  = ( keys $self->Active()->%* );
    # Check that tied choices at the top won't be
    # eliminated. alist is looped over twice because we
    # don't want to report the scores when the list is
    # reduced to either a condorcet winner or tied situation.
    for my $A (@alist) {
      unless ( max( values $scores->%* ) ) {
        last CONDORCETLOSERLOOP;
      }
    }
    $wordy .= YAML::XS::Dump($scores);
    for my $A (@alist) {
      if ( $loser->( $scores->{$A} ) ) {
        push @eliminated, ($A);
        $wordy .= "Eliminationg Condorcet Loser: *$A*\n";
        delete $self->{'Active'}{$A};
        $unfinished = 1;
        next CONDORCETLOSERLOOP;
      }
    }
  }
  my $elimstr =
    scalar(@eliminated)
    ? "Eliminated Condorcet Losers: " . join( ', ', @eliminated ) . "\n"
    : "No Condorcet Losers Eliminated\n";
  return {
    verbose      => $wordy,
    terse        => $elimstr,
    eliminated   => \@eliminated,
    eliminations => scalar(@eliminated),
  };
}

sub CondorcetWinner( $self ) {
  my $scores  = $self->ScoreMatrix;
  my @choices = keys $scores->%*;
  # # if there is only one choice left they win.
  # if ( scalar(@choices) == 1 ) { return $choices[0]}
  my $mustwin = scalar(@choices) - 1;
  my $winner  = '';
  for my $c (@choices) {
    if ( $scores->{$c} == $mustwin ) {
      $winner .= $c;
    }
  }
  return $winner;
}

sub GreatestLoss ( $self, $A ) {
  my $bigloss = 0;
GREATESTLOSSLOOP:
  for my $B ( keys $self->Active()->%* ) {
    next GREATESTLOSSLOOP if $B eq $A;
    my %result = $self->{'Matrix'}{$A}{$B}->%*;
# warn "$A : $B loser $result{'loser'} : margin $result{'margin'} $A: $result{$A} $B: $result{$B}";
    if ( $result{'loser'} eq $A ) {
      $bigloss = $result{'margin'} if $result{'margin'} > $bigloss;
    }
  }
  return $bigloss;
}

sub RankGreatestLoss ( $self, $active = undef ) {
  my %loss = ();
  $active = $self->Active() unless defined $active;
  for my $A ( keys $active->%* ) {
    $loss{$A} = $self->GreatestLoss($A);
  }
  return Vote::Count::RankCount->Rank( \%loss );
}

# reset active to choices
sub ResetActive ( $self ) {
  $self->{'Active'} = $self->BallotSet->{'choices'};
}

sub _getsmithguessforchoice ( $h, $matrix ) {
  my @winners = ($h);
  for my $P ( keys $matrix->{$h}->%* ) {
    if ( $matrix->{$h}{$P}{'winner'} eq $P ) {
      push @winners, ($P);
    }
    elsif ( $matrix->{$h}{$P}{'tie'} ) {
      push @winners, ($P);
    }
  }
  return ( map { $_ => 1 } @winners );
}

sub GetPairResult ( $self, $A, $B ) {
  return $self->{'Matrix'}{$A}{$B};
}

sub GetPairWinner ( $self, $A, $B ) {
  my $winner = $self->{'Matrix'}{$A}{$B}{'winner'};
  return $winner if $winner;
  return '';
}

sub SmithSet ( $self ) {
  my $matrix    = $self->{'Matrix'};
  my @alist     = ( keys $self->Active()->%* );
  my $sets      = {};
  my $setcounts = {};
  # my $shortest = scalar(@list);
  for my $h (@alist) {
    my %set = Vote::Count::Matrix::_getsmithguessforchoice( $h, $matrix );
    $sets->{$h} = \%set;
    # the keys of setcounts are the counts
    $setcounts->{ scalar( keys %set ) }{$h} = 1;
  }
  my $proposal = {};
  my $minset   = min( keys( $setcounts->%* ) );
  for my $h ( keys $setcounts->{$minset}->%* ) {
    for my $k ( keys( $sets->{$h}->%* ) ) {
      $proposal->{$k} = 1;
    }
  }
SMITHLOOP: while (1) {
    my $cntchoice = scalar( keys $proposal->%* );
    for my $h ( keys $proposal->%* ) {
      $proposal = { %{$proposal}, %{ $sets->{$h} } };
    }
    # done when no choices get added on a pass through loop
    if ( scalar( keys $proposal->%* ) == $cntchoice ) {
      last SMITHLOOP;
    }
  }
  return $proposal;
}

# ScoreMatrix as a table.
sub ScoreTable ( $self ) {
  my $scores = $self->ScoreMatrix();
  my @header = ( 'Choice', 'Score' );
  my @rows   = ( \@header );
  for my $c ( sort_hash( $scores, 'numeric', 'desc' ) ) {
    # for my $c ( sort ( keys $scores->%* ) ) {
    push @rows, [ $c, $scores->{$c} ];
  }
  return generate_markdown_table( rows => \@rows );
}

sub MatrixTable ( $self, $options = {} ) {
  my @header = ( 'Choice', 'Wins', 'Losses', 'Ties' );
  # the options option was never fully implemented, it shows what the
  # structure would be if one were or if I finished the feature.
  # leaving the code in place even though its useless.
  my $o_topcount =
    defined $options->{'topcount'} ? $options->{'topcount'} : 0;
  push @header, 'Top Count' if $o_topcount;
  my @active = sort ( keys $self->Active()->%* );
  my @rows = ( \@header );    # [ 'Rank', 'Choice', 'TopCount']);
  for my $A (@active) {
    my $wins     = 0;
    my $ties     = 0;
    my $losses   = 0;
    my $topcount = $o_topcount ? $options->{'topcount'} : 0;
  MTNEWROW:
    for my $B (@active) {
      if ( $A eq $B ) { next MTNEWROW }
      elsif ( $self->{'Matrix'}{$A}{$B}{'winner'} eq $A ) {
        $wins++;
      }
      elsif ( $self->{'Matrix'}{$A}{$B}{'winner'} eq $B ) {
        $losses++;
      }
      elsif ( $self->{'Matrix'}{$A}{$B}{'tie'} ) {
        $ties++;
      }
    }
    my @newrow = ( $A, $wins, $losses, $ties );
    push @newrow, $topcount if $o_topcount;
    push @rows, \@newrow;
  }
  return generate_markdown_table( rows => \@rows );
}

sub PairingVotesTable ( $self ) {
  my @rows = ( [qw/Choice Choice Votes Opponent Votes/] );
  my @choices = sort ( keys $self->Active()->%* );
  for my $Choice (@choices) {
    push @rows, [$Choice];
    for my $Opponent (@choices) {
      my $Cstr = $Choice;
      my $Ostr = $Opponent;
      next if $Opponent eq $Choice;
      my $CVote = $self->{'Matrix'}{$Choice}{$Opponent}{$Choice};
      my $OVote = $self->{'Matrix'}{$Choice}{$Opponent}{$Opponent};
      if ( $self->{'Matrix'}{$Choice}{$Opponent}{'winner'} eq $Choice ) {
        $Cstr = "**$Cstr**";
      }
      if ( $self->{'Matrix'}{$Choice}{$Opponent}{'winner'} eq $Opponent ) {
        $Ostr = "**$Ostr**";
      }
      push @rows, [ ' ', $Cstr, $CVote, $Ostr, $OVote ];
    }
  }
  return generate_markdown_table( rows => \@rows );
}

1;

#buildpod

=pod

=head1 Win-Loss Matrix

Condorcet Pairwise Methods require a Win-Loss Matrix. This object takes an RCV BallotSet with an optional Active list and returns the Matrix as an object. The object is capable of Scoring itself, Calculating a Smith Set, and identifying Condorcet Winners and Losers.


=head1 SYNOPSIS

 
 my $Matrix =
   Vote::Count::Matrix->new(
     'BallotSet' => $myVoteCount->BallotSet() );
   my $Scores = $Matrix->ScoreMatrix();
   my %DominantSet = $Matrix->SmithSet()->%*;
   my $CondorcetWinner = $Matrix->CondorcetWinner();



=head1 Tie Breakers

A tie breaker may be specified by setting the Tie::Breaker attribute, see the Tie::Breaker module for more information. If using Range Ballots 'none' and 'approval' are the only currently supported options.


=head2 new

Parameters:


=head3 BallotSet (required)

A Ballot Set reference as generated by ReadBallots, which can be retrieved from a Vote::Count object via the ->BallotSet() method.

Both Ranked Choice and Range BallotSets are supported.


=head3 Active (optional)

A hash reference with active choices as the keys. The default value is all of the choices defined in the BallotSet.


=head3 Logging (optional)

Has the logging methods of L.


=head1 Methods


=head2 MatrixTable

Returns a MarkDown formatted table with the wins losses and ties for each Active Choice as text.


=head2 PairingVotesTable

Returns a MarkDown formatted table with the votes for all of the pairings.


=head2 GetPairResult ( $A, $B )

Returns the results of the pairing of two choices as a hashref.

 
   {
    'FUDGESWIRL' =>  6,
    'loser'      =>  "STRAWBERRY",
    'margin'     =>  2,
    'STRAWBERRY' =>  4,
    'tie'        =>  0,
    'winner'     =>  "FUDGESWIRL"
   }



=head2 GetPairWinner ( $A, $B )

Returns the winner of the pairing of two choices. If there is no Winner it returns a false value (empty string).


=head2 ScoreMatrix

Returns a HashRef of the choices and their Matrix Scores. The scoring is 1 for each win, 0 for losses and ties. In the event a choice has ties but no wins their score will be .001. Where N is the number of choices, a Condorcet Winner will have a score of N-1, a Condorcet Loser will have a score of 0. Since a choice with at least one tie but no wins is not defeated by all other choices they are not a Condorcet Loser, and thus those cases are scored with a near to zero value instead of 0. Methods that wish to treat no wins but tie case as a Condorcet Loser may test for a score less than 1.


=head2 ScoreTable

Returns the ScoreMatrix as a markdown compatible table.


=head2 LeastWins

Returns an array of the choice or choices with the fewest wins.


=head2 CondorcetLoser

Eliminates all Condorcet Losers from the Matrix Object's Active list. Returns a hashref. Takes an optional true false argument (default is false) to include choices that have tied but not won in the elimination.

 
   {
     verbose => 'verbose message',
     terse   => 'terse message',
     eliminated => [ eliminated choices ],
     eliminations => number of eliminated choices,
   };



=head2 CondorcetWinner

Returns either the Condorcet Winner or an empty string if there is none.


=head2 SmithSet

Finds the innermost Smith Set (Dominant Set). [ assistance in finding proof of the algorithm used would be appreciated so it could be correctly referenced in this documentation ]. A Dominant Set is a set which defeats all choices outside of that set. The inner Smith Set is the smallest possible Dominant Set.

Returns a hashref with the keys as the choices of the Smith Set.


=head2 ResetActive

Reset Active list to the choices list of the BallotSet.


=head2 GreatestLoss

Returns the greatest loss for a choice C<<< $MyMatrix->GreatestLoss( $A ) >>>.


=head2 RankGreatestLoss

Returns a RankCount object of the Greatest Loss for each choice.

=cut

#buildpod

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