use strict;
use warnings;
use 5.022;

use feature qw /postderef signatures/;

package Vote::Count::TieBreaker;
use Moose::Role;

no warnings 'experimental';
use List::Util qw( min max sum );
use Path::Tiny;
use Data::Dumper;
use Vote::Count::RankCount;
use Carp;

our $VERSION = '1.10';

=head1 NAME

Vote::Count::TieBreaker

=head1 VERSION 1.10

=head1 Synopsis

  my $Election = Vote::Count->new(
    BallotSet      => $ballotsirvtie2,
    TieBreakMethod => 'approval'
  );

=cut

# ABSTRACT: TieBreaker object for Vote::Count. Toolkit for vote counting.

=head1 Tie Breakers

The most important thing for a Tie Breaker to do is it should use some reproducible difference in the Ballots to pick a winner from a Tie. The next thing it should do is make sense. Finally, the ideal Tie Breaker will resolve when there is any difference to be found. Arguably the best use of Borda Count is as a Tie Breaker, First Choice votes and Approval are also other great choices.

TieBreakMethod is specified as an argument to Vote::Count->new(). The TieBreaker is called internally from the resolution method via the TieBreaker function, which requires the caller to pass its TieBreakMethod.

=head1 TieBreakMethod argument to Vote::Count->new

  'approval'
  'all' [ eliminate all tied choices ]
  'borda' [ applies Borda Count to current Active set ]
  'grandjunction' [ more resolveable than simple TopCount would be ]
  'none' [ eliminate no choices ]
  'precedence' [ requires also setting PrecedenceFile ]

=head1 Grand Junction

The Grand Junction (also known as Bucklin) method is one of the simplest and easiest to Hand Count RCV resolution methods. Other than that it is generally not considered a good method.

Because it is simple, and always resolves, except when ballots are perfectly matched up, it is a great TieBreaker. It is not Later Harm Safe, but heavily favors higher rankings. It is the Vote::Count author's preferred Tie-Breaker.

=head2 The (Standard) Grand Junction Method

Only the Tie-Breaker variant is currently implemented in Vote::Count.

=over

=item 1

Count the Ballots to determine the quota for a majority.

=item 2

Count the first choices and elect a choice which has a majority.

=item 3

If there is no winner add the second choices to the totals and elect the choice which has a majority (or the most votes if more than one choice reaches a majority).

=item 4

Keep adding the next rank to the totals until either there is a winner or all ballots are exhausted.

=item 5

When all ballots are exhausted the choice with the highest total wins.

=back

=head2 As a Tie Breaker

The Tie Breaker Method is modified.

Instead of Majority, any choice with a current total less than another is eliminated. This allows resolution of any number of choices in a tie.

The winner is the last choice remaining.

=head2 TieBreakerGrandJunction

  my $resolve = $Election->TieBreakerGrandJunction( $choice1, $choice2 [ $choice3 ... ]  );
  if ( $resolve->{'winner'}) { say "Tie Winner is $resolve->{'winner'}"}
  elsif ( $resolve->{'tie'}) {
    my @tied = $resolve->{'tied'}->@*;
    say "Still tied between @tied."
  }

The Tie Breaking will be logged to the verbose log, any number of tied choices may be provided.

=cut

has 'TieBreakMethod' => (
  is       => 'rw',
  isa      => 'Str',
  required => 0,
);

# This is only used for the precedence tiebreaker and fallback!
has 'PrecedenceFile' => (
  is       => 'rw',
  isa      => 'Str',
  required => 0,
  trigger  => \&_triggercheckprecedence,
);

has 'TieBreakerFallBackPrecedence' => (
  is      => 'rw',
  isa     => 'Bool',
  default => 0,
  lazy    => 0,
  trigger => \&_triggercheckprecedence,
);

sub _triggercheckprecedence ( $I, $new, $old = undef ) {
  unless ( $I->PrecedenceFile() ) {
    $I->PrecedenceFile('/tmp/precedence.txt');
    $I->logt( "Generated FallBack TieBreaker Precedence Order: \n"
        . join( ', ', $I->CreatePrecedenceRandom() ) );
  }
  $I->{'PRECEDENCEORDER'} = undef;    # clear cached if the file changes.
}

sub TieBreakerGrandJunction ( $self, @tiedchoices ) {
  my $ballots = $self->BallotSet()->{'ballots'};
  my %current = ( map { $_ => 0 } @tiedchoices );
  my $deepest = 0;
  for my $b ( keys $ballots->%* ) {
    my $depth = scalar $ballots->{$b}{'votes'}->@*;
    $deepest = $depth if $depth > $deepest;
  }
  my $round = 1;
  while ( $round <= $deepest ) {
    $self->logv("Tie Breaker Round: $round");
    for my $b ( keys $ballots->%* ) {
      my $pick = $ballots->{$b}{'votes'}[ $round - 1 ] or next;
      if ( defined $current{$pick} ) {
        $current{$pick} += $ballots->{$b}{'count'};
      }
    }
    my $max = max( values %current );
    for my $c ( sort @tiedchoices ) {
      $self->logv("\t$c: $current{$c}");
    }
    for my $c ( sort @tiedchoices ) {
      if ( $current{$c} < $max ) {
        delete $current{$c};
        $self->logv("Tie Breaker $c eliminated");
      }
    }
    @tiedchoices = ( sort keys %current );
    if ( 1 == @tiedchoices ) {
      $self->logv("Tie Breaker Won By: $tiedchoices[0]");
      return { 'winner' => $tiedchoices[0], 'tie' => 0, 'tied' => [] };
    }
    $round++;
  }
  if ( $self->TieBreakerFallBackPrecedence() ) {
    $self->logv('Applying Precedence fallback');
    return $self->TieBreakerPrecedence(@tiedchoices);
  }
  else {
    return { 'winner' => 0, 'tie' => 1, 'tied' => \@tiedchoices };
  }
}

=head1 TieBreaker

Implements some basic methods for resolving ties. The default value for IRV is 'all', and the default value for Matrix is 'none'. 'all' is inappropriate for Matrix, and 'none' is inappropriate for IRV.

  my @keep = $Election->TieBreaker( $tiebreaker, $active, @tiedchoices );

TieBreaker returns a list containing the winner, if the method is 'all' the list is empty, if 'none' the original @tiedchoices list is returned. If the TieBreaker is a tie there will be multiple elements.

=head1 Precedence

Since many existing Elections Rules call for Random, and Vote::Count does not accept Random as the result will be different bewtween runs, Precedence allows the Administrators of an election to randomly or arbitrarily determine who will win ties before running Vote::Count.

The Precedence list takes the choices of the election one per line. Choices defeat any choice lower than them in the list. When Precedence is used an additional attribute must be specified for the Precedence List.

 my $Election = Vote::Count->new(
   BallotSet => read_ballots('somefile'),
   TieBreakMethod => 'precedence',
   PrecedenceFile => '/path/to/precedencefile');

=head2 CreatePrecedenceRandom

Creates a Predictable Psuedo Random Precedence file, and returns the list. Randomizes the choices using the number of ballots as the Random Seed for Perl's built in rand() function. For any given Ballot File, it will always return the same list. If the precedence filename argument is not given it defaults to '/tmp/precedence.txt'. This is the best solution to use where the Rules call for Random, in a large election the number of ballots cast will be sufficiently random, while anyone with access to Perl can reproduce the Precedence file.

  my @precedence = Vote::Count->new( BallotSet => read_ballots('somefile') )
    ->CreatePrecedenceRandom( '/tmp/precedence.txt');

=head2 TieBreakerFallBackPrecedence

This optional argument enables or disables using precedence as a fallback, generates /tmp/precedence.txt if no PrecedenceFile is specified. Default is off.

=head1 UntieList

Sort a list in an order determined by a TieBreaker method, sorted in Descending Order. The TieBreaker must be a method that returns a RankCount object, Borda, TopCount, and Approval, Precedence. To guarrantee reliable resolution Precedence must be used or have been set for fallback.

  my @orderedlosers = $Election->UntieList( 'Approval', @unorderedlosers );

=head1 UntieActive

Produces a precedence list of all the active choices in the election. Takes a first and optional second method name, if one of the methods is not Precedence, TieBreakerPrecedence must be true. The methods may be TopCount, Approval, or any other method that returns a RankCount object. Returns a RankCount object (with the OrderedList method enabled).

  my $precedenceRankCount = $Election->UntieActive( 'TopCount', 'Approval');

=cut

sub _precedence_sort ( $I, @list ) {
  my %ordered = ();
  my $start   = 0;
  if ( defined $I->{'PRECEDENCEORDER'} ) {
    %ordered = $I->{'PRECEDENCEORDER'}->%*;
  }
  else {
    for ( split /\n/, path( $I->PrecedenceFile() )->slurp() ) {
      $_ =~ s/\s//g;    #strip out any accidental white space
      $ordered{$_} = ++$start;
    }
    for my $c ( $I->GetChoices ) {
      unless ( defined $ordered{$c} ) {
        croak "Choice $c missing from precedence file\n";
      }
    }
    $I->{'PRECEDENCEORDER'} = \%ordered;
  }
  my %L = map { $ordered{$_} => $_ } @list;
  return ( map { $L{$_} } ( sort { $a <=> $b } keys %L ) );
}

sub TieBreakerPrecedence ( $I, @tiedchoices ) {
  my @list = $I->_precedence_sort(@tiedchoices);
  return { 'winner' => $list[0], 'tie' => 0, 'tied' => [] };
}

sub CreatePrecedenceRandom ( $I, $outfile = '/tmp/precedence.txt' ) {
  my @choices    = $I->GetActiveList();
  my %randomized = ();
  srand( $I->BallotSet()->{'votescast'} );
  while (@choices) {
    my $next   = shift @choices;
    my $random = int( rand(1000000) );
    if ( defined $randomized{$random} ) {
      # collision, this choice needs to do again.
      unshift @choices, ($next);
    }
    else {
      $randomized{$random} = $next;
    }
  }
  my @precedence =
    ( map { $randomized{$_} } sort { $a <=> $b } ( keys %randomized ) );
  path($outfile)->spew( join( "\n", @precedence ) . "\n" );
  return @precedence;
}

sub TieBreaker ( $I, $tiebreaker, $active, @tiedchoices ) {
  no warnings 'uninitialized';
  if ( $tiebreaker eq 'none' ) { return @tiedchoices }
  if ( $tiebreaker eq 'all' )  { return () }
  my $choices_hashref = { map { $_ => 1 } @tiedchoices };
  my $ranked          = undef;
  if ( $tiebreaker eq 'borda' ) {
    $ranked = $I->Borda($active);
  }
  elsif ( $tiebreaker eq 'borda_all' ) {
    $ranked = $I->Borda( $I->BallotSet()->{'choices'} );
  }
  elsif ( $tiebreaker eq 'approval' ) {
    $ranked = $I->Approval($choices_hashref);
  }
  elsif ( $tiebreaker eq 'topcount' ) {
    $ranked = $I->TopCount($choices_hashref);
  }
  elsif ( $tiebreaker eq 'grandjunction' ) {
    my $GJ = $I->TieBreakerGrandJunction(@tiedchoices);
    if    ( $GJ->{'winner'} ) { return $GJ->{'winner'} }
    elsif ( $GJ->{'tie'} )    { return $GJ->{'tied'}->@* }
    else { croak "unexpected (or no) result from $tiebreaker!\n" }
  }
  elsif ( $tiebreaker eq 'precedence' ) {
    # The one nice thing about precedence is that there is always a winner.
    return $I->TieBreakerPrecedence(@tiedchoices)->{'winner'};
  }
  else { croak "undefined tiebreak method $tiebreaker!\n" }
  my @highchoice = ();
  my $highest    = 0;
  my $counted    = $ranked->RawCount();
  for my $c (@tiedchoices) {
    if ( $counted->{$c} > $highest ) {
      @highchoice = ($c);
      $highest    = $counted->{$c};
    }
    elsif ( $counted->{$c} == $highest ) {
      push @highchoice, $c;
    }
  }
  my $terse =
      "Tie Breaker $tiebreaker: "
    . join( ', ', @tiedchoices )
    . "\nwinner(s): "
    . join( ', ', @highchoice );
  $I->{'last_tiebreaker'} = {
    'terse'   => $terse,
    'verbose' => $ranked->RankTable(),
  };
  if ( @highchoice > 1 ) {
    if ( $I->TieBreakerFallBackPrecedence() ) {
      return ( $I->TieBreakerPrecedence(@tiedchoices)->{'winner'} );
    }
  }
  return (@highchoice);
}

sub UnTieList ( $I, $method, @tied ) {
  return $I->_precedence_sort( @tied ) if ( lc($method) eq 'precedence' );
  unless ( $I->TieBreakerFallBackPrecedence() ) {
    croak
"TieBreakerFallBackPrecedence must be enabled or the specified method must be precedence to use UnTieList";
  }
  my @ordered = ();
  my %active  = ( map { $_ => 1 } @tied );
  # method should be topcount borda or approval which all take argument of active.
  my $RC = $I->$method(\%active)->HashByRank();

  # my $nonrc   = 0;
  for my $level ( sort { $a <=> $b } ( keys $RC->%* ) ) {
    my @l = @{ $RC->{$level} };
    my @suborder =
      ( 1 == @{ $RC->{$level} } )
      ? @{ $RC->{$level} }
      : $I->_precedence_sort( @l );
    push @ordered, @suborder;
  }
  return @ordered;
}

sub UntieActive ( $I, $method1, $method2='precedence' ) {
   if ( lc($method1) eq 'precedence' ) {
    return Vote::Count::RankCount->newFromList(
      $I->_precedence_sort( $I->GetActiveList() ));
    }
  my $hasprecedence = 0;
  $hasprecedence = 1 if 1 == $I->TieBreakerFallBackPrecedence();
  $hasprecedence = 1 if lc($method2) eq 'precedence';
  unless ($hasprecedence) {
    croak
"TieBreakerFallBackPrecedence must be enabled or one of the specified methods must be precedence to use UntieActive";
  }
  my @ordered = ();
  my $first   = $I->$method1()->HashByRank();

  for my $level ( sort { $a <=> $b } ( keys %{$first} ) ) {
    my @l = @{ $first->{$level} };
    my @suborder =
      ( 1 == @{ $first->{$level} } )
      ? @{ $first->{$level} }
      : $I->UnTieList( $method2, @l );
    push @ordered, @suborder;
  }
  my $position = 0;
  return Vote::Count::RankCount->newFromList( @ordered );
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
