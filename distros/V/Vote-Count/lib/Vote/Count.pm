use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

# ABSTRACT: toolkit for implementing voting methods.

package Vote::Count;
use namespace::autoclean;
use Moose;

# use Data::Dumper;
use Time::Piece;
use Path::Tiny;
use Vote::Count::Matrix;
use Storable 3.15 'dclone';

no warnings 'experimental';

our $VERSION='1.05';

=head1 NAME

Vote::Count


=head1 VERSION 1.05

=cut

# ABSTRACT: Parent Module for Vote::Count. Toolkit for vote counting.

has 'BallotSet' => ( is => 'ro', isa => 'HashRef', required => 1 );

has 'Active' => (
  is      => 'rw',
  isa     => 'HashRef',
  lazy    => 1,
  builder => 'ResetActive',
);

sub ResetActive ( $self ) { return dclone $self->BallotSet()->{'choices'} }

sub SetActive ( $self, $active ) {
  # Force deref
  $self->{'Active'} = dclone $active;
}

# I was typing the equivalent too often. made a method.
sub SetActiveFromArrayRef ( $self, $active ) {
  $self->{'Active'} = { map { $_ => 1 } $active->@* };
}

sub GetActive ( $self ) {
  # Force deref
  my $active = $self->Active();
  return dclone $active;
}

has TieBreakMethod => (
  is       => 'rw',
  isa      => 'Str',
  required => 0,
);

# This is only used for the precedence tiebreaker!
has PrecedenceFile => (
  is       => 'rw',
  isa      => 'Str',
  required => 0,
);

has 'PairMatrix' => (
  is      => 'ro',
  isa     => 'Object',
  lazy    => 1,
  builder => '_buildmatrix',
);

sub _buildmatrix ( $self ) {
  my $tiebreak =
    defined( $self->TieBreakMethod() )
    ? $self->TieBreakMethod()
    : 'none';
  return Vote::Count::Matrix->new(
    BallotSet      => $self->BallotSet(),
    Active         => $self->Active(),
    TieBreakMethod => $tiebreak,
    LogTo          => $self->LogTo() . '_matrix',
  );
}

sub UpdatePairMatrix ( $self, $active = undef ) {
  $active = $self->Active() unless defined $active;
  $self->{'PairMatrix'} = Vote::Count::Matrix->new(
    BallotSet => $self->BallotSet(),
    Active    => $active
  );
}

sub BUILD {
  my $self = shift;
  # Verbose Log
  $self->{'LogV'} = localtime->cdate . "\n";
  # Debugging Log
  $self->{'LogD'} = qq/Vote::Count Version $VERSION\n/;
  $self->{'LogD'} .= localtime->cdate . "\n";
  # Terse Log
  $self->{'LogT'} = '';
}

# load the roles providing the underlying ops.
with 
  'Vote::Count::Approval',
  'Vote::Count::Borda',
  'Vote::Count::Floor',
  'Vote::Count::IRV',
  'Vote::Count::Log',
  'Vote::Count::Score',
  'Vote::Count::TieBreaker',
  'Vote::Count::TopCount',
  ;

sub VotesCast ( $self ) {
  return $self->BallotSet()->{'votescast'};
}

sub VotesActive ( $self ) {
  unless ( $self->BallotSet()->{'options'}{'rcv'} ) {
    die "VotesActive Method only supports rcv"
  }
  my $set         = $self->BallotSet();
  my $active      = $self->Active();
  my $activeCount = 0;
LOOPVOTESACTIVE:
    for my $B ( values $set->{ballots}->%* ) {
        for my $V ( $B->{'votes'}->@* ) {
            if ( defined $active->{$V} ) {
                $activeCount += $B->{'count'};
                next LOOPVOTESACTIVE;
            }
        }
    }
  return $activeCount;
}

sub BallotSetType ( $self ) {
  if ( $self->BallotSet()->{'options'}{'rcv'} ) {
    return 'rcv';
  }
  elsif ( $self->BallotSet()->{'options'}{'range'} ) {
    return 'range';
  }
  else {
    die "BallotSetType is undefined or unknown type.";
  }
}

__PACKAGE__->meta->make_immutable;
1;

#buildpod

=pod

=head1 Vote::Count


=head2 A Toolkit for determining the outcome of Preferential Ballots.

Provides a Toolkit for implementing multiple voting systems, allowing a wide range of method options. This library allows the creation of election resolution methods matching a set of Election Rules that are written in an organization's governing rules, and not requiring the bylaws to specify the rules of the software that will be used for the election, especially important given that many of the other libraries available do not provide a bylaws compatible explanation of their process.

  use 5.022; # Minimum Perl, or any later Perl.
  use feature qw /postderef signatures/;

  use Vote::Count;
  use Vote::Count::ReadBallots;
  use Vote::Count::Method::CondorcetDropping;

  # example uses biggerset1 from the distribution test data.
  my $ballotset = read_ballots 't/data/biggerset1.txt' ;
  my $CondorcetElection =
    Vote::Count::Method::CondorcetDropping->new(
      'BallotSet' => $ballotset ,
      'DropStyle' => 'all',
      'DropRule'  => 'topcount',
    );
  # ChoicesAfterFloor a hashref of choices meeting the
  # ApprovalFloor which defaulted to 5%.
  my $ChoicesAfterFloor = $CondorcetElection->ApprovalFloor();
  # Apply the ChoicesAfterFloor to the Election.
  $CondorcetElection->Active( $ChoicesAfterFloor );
  # Get Smith Set and the Election with it as the Active List.
  my $SmithSet = $CondorcetElection->Matrix()->SmithSet() ;
  $CondorcetElection->logt(
    "Dominant Set Is: " . join( ', ', keys( $SmithSet->%* )));
  my $Winner = $CondorcetElection->RunCondorcetDropping( $SmithSet )->{'winner'};

  # Create an object for IRV, use the same Floor as Condorcet

  my $IRVElection = Vote::Count->new(
    'BallotSet' => $ballotset,
    'Active' => $ChoicesAfterFloor );
  # Get a RankCount Object for the
  my $Plurality = $IRVElection->TopCount();
  # In case of ties RankCount objects return top as an array, log the result.
  my $PluralityWinner = $Plurality->Leader();
  $IRVElection->logv( "Plurality Results", $Plurality->RankTable);
  if ( $PluralityWinner->{'winner'}) {
    $IRVElection->logt( "Plurality Winner: ", $PluralityWinner->{'winner'} )
  } else {
    $IRVElection->logt(
      "Plurality Tie: " . join( ', ', $PluralityWinner->{'tied'}->@*) )
  }
  my $IRVResult = $IRVElection->RunIRV();

  # Now print the logs and winning information.
  say $CondorcetElection->logv();
  say $IRVElection->logv();
  say '*'x60;
  say "Plurality Winner: $PluralityWinner->{'winner'}";
  say "IRV Winner: $IRVResult->{'winner'}";
  say "Condorcet Winner: $Winner";


=head1 Overview


=head2 Brief Review of Voting Methods

Several alternatives have been proposed to the simple vote for a single choice method that has been used in most elections for a single member. In addition a number of different methods have been used for multiple members. For alternative single member voting, the three common alternatives are I<Approval> (voters indicate all choices that they approve of), I<Ranked Choice> (Voters rank the choices), and I<Score> also known as I<Range> (voters give choices a score according to a scale).

I<Vote for One> ballots may be resolved by one of two methods: I<Majority> and I<Plurality>. Majority vote requires a majority of votes to win (but frequently produces no winner), and Plurality which selects the choice with the most votes.

Numerous methods have been proposed and tried for I<Ranked Choice Ballots>. To compare these methods a number of criteria have been developed. While Mathematicians often treat these criteria as absolutes, from a policy perspective it may be more valuable to see them as a spectrum where a method may be considered to satisfy or fail with varying degrees of severity. From a policy perspective it is appropriate to group most of the criteria into a single group: Consistency. Finally Mathematicians, typically, do not directly consider Complexity, but from a policy perspective this is just as important as any of the other criteria, and is definitely a scale not an absolute.


=head3 The Criteria for Resolving Ranked Choice (including Score) Ballots


=head4 Later Harm

Marking a later Choice on a Ballot should not cause a Voter's higher ranked choice to lose.


=head4 Condorcet Criteria

I<Condorcet Loser> states that a method should not choose a winner that would be defeated in a direct matchup to all other choices.

I<Condorcet Winner> states a choice which defeats all others in direct matchups should be the Winner.

I<Smith Criteria> the winner should belong to the smallest set of choices which defeats all choices outside of that set.


=head4 Consistency Criteria

The Consistency Criteria collectively state: Changes to non-winning alternatives that would not obviously alter the outcome should not change the winner. Adding or removing non-winning choices, or altering the votes for non-winning choices, except in a manner which directly changes the outcome should not alter the outcome. If votes are moved between non-winning alternatives in a manner that has no direct affect on the winner, the winner should not change. Changes to non-winning choices which increase support for the winner should not then cause a different choice to win.

To illustrate inconsistency: suppose every morning we vote on a flavor of Ice Cream and Chocolate always wins; one morning the three voters who always vote 1:RockyRoad 2:Chocolate simply vote for Chocolate, consistency is violated if Chocolate loses on that day.

Cloning occurs when similar choices are available, such as Vanilla and Vanilla Bean. If one of the clones would win without the presence of the other, the presence of both should not cause a non-clone to win.

The cases described above: Monotonocity, Independence of Irrelevant Alternatives and Clone Independence are normally discussed as separate criteria rather than components of one. Additional sub-criteria that haven't been mentioned include: Reversal Symmetry, Participation Consistency, and Later No Help (which could also be considered a sub-criteria of Later Harm).

There is a specific Criteria that is sometimes called Consistency, in this discussion consistency is discussed in the broad context. No method passes every possible consistency criteria, from a policy perspective a method is consistent if it has no major consistency failures.


=head4 Complexity

Is it feasible to count 100 ballots by hand? How difficult is it to understand the process (can the average middle school student understand it at all)? How many steps?


=head4 Resolvability

I<Majority> meets all of the above criteria, however, unless votes are restricted to two choices, it will frequently fail to provide a winner, or even a tie. No method can be completely impervious to ties. Methods that are not Resolvable are frequently combined with other methods, I<Instant Runoff Voting> is a compound method with I<Majority>, and all usable I<Condorcet> Methods combine seeking a Condorcet Winner with some other process.


=head4 Incentive for Strategic Voting

Voting systems have weaknesses which can incentivize voters to vote in an insincere manner. Later Harm Violation is a strong driver for tactical voting. Inconsistency may create circumstances by which a block of voters by voting in certain ways can boost or harm a choice, this vulnerability type is often referred to as an attack.


=head3 Arrow's Theorem

Arrows Theorem states that it is impossible to have a system that can resolve Ranked Choice Ballots which meets Later Harm and Condorcet Winner. To extend the notion, if it is impossible to meet two criteria it is truly impossible to meet five. Every method  has a trade off, where it will fail some criteria and fail them to different degrees.


=head3 Popular Ranked Choice Resolution Systems


=head4 Instant Runoff Voting (IRV is also known as Hare System, Alternative Vote)

Seeks a Majority Winner. If there is none the lowest choice is eliminated until there is a Majority Winner or all remaining choices have the same number of votes.

=over

=item *

Easy to Hand Count and Easy to Understand.


=item *

Meets Later Harm.


=item *

Fails Condorcet Winner (but meets Condorcet Loser).


=item *

Fails many Consistency Criteria (The example given for Consistency can happen with IRV). IRV handles clones poorly.


=back


=head4 Borda Count and Scoring

When Range (Cardinal) Ballots are used, the scores assigned by the voters are tallied to score the choices.

Since Scoring is native to Range Ballots, to use the approach to resolve Ranked Ballots requires a method of assigning scores.

Borda Count Scores choices on a ballot based on their position. Borda supporters often disagree about the weighting rule to use in the scoring. Iterative Borda Methods (Baldwin, Nansen) eliminate the lowest choice(s) and recalculate the Borda score ignoring eliminated choices (if your second choice is eliminated your third choice is promoted).

=over

=item *

Easy to Understand.


=item *

Fails Later Harm.


=item *

Fails Condorcet Winner.


=item *

Inconsistent.


=item *

The basic Borda Method is vulnerable to a Cloning Attack, but not Range Ballot Scoring and iterative Borda methods.


=back


=head4 Condorcet

Technically this family of methods should be called Condorcet Pairwise, because any method that meets both Condorcet Criteria is technically a Condorcet Method. However, in discussion and throughout this software collection the term Condorcet will refer to  methods which uses a Matrix of Wins and Losses derived from direct pairing of choices and seeks to identify a Condorcet Winner.

The basic Condorcet Method will frequently fail to identify a winner. One possibility is a Loop (Condorcet's Paradox) Where A > B, B > C, and C > A. Another possibility is a knot (not an accepted term, but one which will be used in this documentation). To make Condorcet resolvable a second method is typically used to resolve Loops and Knots.

=over

=item *

Complexity Varies among sub-methods.



=item *

Fails Later Harm.



=item *

Meets both Condorcet Criteria.



=item *

When a Condorcet Winner is present Consistency is very high. When there is no Condorcet Winner this Consistency applies between a Dominant (Smith) Set and the rest of the choices, but not within the Smith Set. Sub-methods vary in consistency when there is no Condorcet Winner.



=back


=head3 Range (Score) Voting Systems

Most Methods for Ranked Choice Ballots can be used for Range Ballots.

Score Voting proposals typically implement I<Borda Count>, with a fixed depth of choices. I<STAR>, creates a virtual runoff between the top two I<Borda Count> Choices.

Advocates claim that this Ballot Style is a better expression of voter preference. Where it shows a clear advantage is in allowing Voters to directly mitigate Later Harm by ranking a strongly favored choice with the highest score and weaker choices with the lowest. The downside to this strategy is that the voter is giving little help to later choices reaching the automatic runoff. Given a case with two roughly equal main factions, where one faction give strong support to all of its options, and the other faction's supporters give weak support to all later choices; the runoff will be between the two best choices of the first faction, even if the choices of the second faction all defeat any of the first's choices in pairwise comparison.

The Range Ballot resolves the Borda weighting problem and allows the voter to manage the later harm effect, so it is clearly a better choice than Borda. Condorcet and IRV can resolve Range Ballots, but ignore the extra information and would prefer strict ordinality (not allowing equal ranking).

Voters may find the Range Ballot to be more complex than the Ranked Choice Ballot.


=head1 Objective and Motivation

I wanted to be able to evaluate alternative methods for resolving elections and couldn't find a flexible enough existing library in any of the popular general purpose and web development languages: Perl, PHP, Python, Ruby, JavaScript, nor in the newer language Julia (created as an alternative to R and other math languages). More recently I was writing a bylaws proposal to use RCV and found that the existing libraries and services were not only constrained in what options they can provide, but also didn't always document them clearly, making it a challenge to have a method described in bylaws where it could be guaranteed hand and machine counts would agree.

The objective is to have a library that can handle any of the myriad variants that one might consider either from a study perspective or what is called for by the elections rules of our entity.


=head1 Basics


=head2 Reading Ballots

The Vote::Count::ReadBallots library provides functionality for reading files from disc. Currently it defines a format for a ballot file and reads that from disk. In the future additional formats may be added. Range Ballots may be in either JSON or YAML formats.


=head2 Voting Method and Component Modules

The Modules in the space Vote::Count::%Component% provide functionality needed to create a functioning Voting Method. Many of these are consumed as Roles by the Vote::Count object, some such as RankCount and Matrix return their own objects.

The Modules in the space Vote::Count::Method::%Something% implement a Voting Method such as IRV. These Modules inherit the parent Vote::Count and all of the Components available to it. These modules all return a Hash Reference with the following key: I<winner>, some return additional keys. Methods that can be tied will have additional keys I<tie> and I<tied>. When there is no winner the value of I<winner> will be false.

Simpler Methods such as single iteration Borda or Approval can be run directly from the Vote::Count Object.


=head2 Vote::Count Module

The Core Module requires a Ballot Set (which can be obtained from ReadBallots).

  my $Election = Vote::Count->new(
      BallotSet => read_ballots( 'ballotfile'), # imported from ReadBallots
      ActiveSet => { 'A' => 1, 'B' => 1, 'C' => 1 }, # Optional
  );


=head3 Optional Paramters to Vote::Count


=head4 Active

A Hashref with the active choices as keys. The Active Choices are represented by a Hashref because it is easier to manipulate hash keys than it is to manipulate random array elements.


=head4 LogTo

Sets a path and Naming pattern for writing logs with the WriteLogs method.

  'LogTo' => '/loggingI<path/election>name'

The WriteLogs method will write the logs appending '.brief', '.full', and '.debug' for the three logs where brief is a summary written with the logt (log terse) method, the full transcript log written with logv, and finally the debug log written with logd. Each higher log level captures all events of the lower log levels.

The default log location is '/tmp/votecount'.

When logging from your methods, use logt for events that produce a summary, use logv for events that should be in the full transcript such as round counts, and finally debug is for events that may be helpful in debugging but which should not be in the transcript.


=head3 Active Sets

Active sets are typically represented as a Hash Reference where the keys represent the active choices and the value is true. The VoteCount Object contains an Active Set which can be Accessed or set via the ->Active() method. The ->GetActive and ->SetActive methods are preferred because they break the reference link between the object's copy and the external copy of the Active set.

Most Components will take an argument for $activeset or default to the current Active set of the Vote::Count object, which will default to the Choices defined in the BallotSet.


=head1 Vote::Count Methods

=over

=item *

new



=item *

Active: Set or Get Active Set as HashRef



=item *

ResetActive: Sets the Active Set to the full choices list of the BallotSet.



=item *

SetActive: Sets the Active Set to provided HashRef. Using the Active method may preserve a reference between the Active Set and the HashRef, SetActive will not. The values to the hashref should evaluate as True.



=item *

SetActiveFromArrayRef: Same as SetActive except it takes an ArrayRef of the choices to be set as Active.



=item *

BallotSet: Get BallotSet



=item *

PairMatrix: Get a Matrix Object for the Active Set. Generated and cached on the first request.



=item *

UpdatePairMatrix: Regenerate and cache Matrix with current Active Set.



=item *

VotesCast: Returns the number of votes cast.



=item *

VotesActive: Returns the number of non-exhausted ballots based on the current Active Set.



=back


=head2 Components


=head3 Catalog of Methods

Directory of Vote Counting Methods linking to the Vote::Count module for it.

=over

=item *

L<Catalog|https://metacpan.org/pod/distribution/Vote-Count/Catalog.pod>


=back


=head3 Consumed As Roles By Vote::Count

=over

=item *

L<Vote::Count::Approval|https://metacpan.org/pod/Vote::Count::Approval>


=item *

L<Vote::Count::Borda|https://metacpan.org/pod/Vote::Count::Borda>


=item *

L<Vote::Count::Floor|https://metacpan.org/pod/Vote::Count::Floor>


=item *

L<Vote::Count::IRV|https://metacpan.org/pod/Vote::Count::IRV>


=item *

L<Vote::Count::TopCount|https://metacpan.org/pod/Vote::Count::TopCount>


=item *

L<Vote::Count::Redact|https://metacpan.org/pod/Vote::Count::Redact>


=item *

L<Vote::Count::Score|https://metacpan.org/pod/Vote::Count::Score>


=item *

L<Vote::Count::TieBreaker|https://metacpan.org/pod/Vote::Count::TieBreaker>


=back


=head3 Return Their Own Objects

=over

=item *

L<Vote::Count::Matrix|https://metacpan.org/pod/Vote::Count::Matrix>


=item *

L<Vote::Count::RankCount|https://metacpan.org/pod/Vote::Count::RankCount>


=back


=head3 Voting Methods

=over

=item *

L<Vote::Count::Method::CondorcetDropping|https://metacpan.org/pod/Vote::Count::Method::CondorcetDropping>


=item *

L<Vote::Count::Method::CondorcetIRV|https://metacpan.org/pod/Vote::Count::Method::CondorcetIRV>


=item *

L<Vote::Count::Method::CondorcetVsIRV|https://metacpan.org/pod/Vote::Count::Method::CondorcetVsIRV>


=item *

L<Vote::Count::Method::STAR|https://metacpan.org/pod/Vote::Count::Method::STAR>


=back


=head3 Non Object Oriented Components

=over

=item *

L<Vote::Count::Redact|https://metacpan.org/pod/Vote::Count::Redact>


=back


=head3 Utilities

=over

=item *

L<Vote::Count::ReadBallots|https://metacpan.org/pod/Vote::Count::ReadBallots>


=item *

L<Vote::Count::Start|https://metacpan.org/pod/Vote::Count::Start>


=back


=head3 Additional Documentation

=over

=item *

L<Catalog|https://metacpan.org/pod/distribution/Vote-Count/lib/Vote/Catalog.pod>


=item *

L<Hand Count|https://metacpan.org/pod/distribution/Vote-Count/lib/Vote/Hand_Count.pod>


=item *

L<Multi Member|https://metacpan.org/pod/distribution/Vote-Count/lib/Vote/MultiMember.pod>


=item *

L<Vote::Count::Start|https://metacpan.org/pod/Vote::Count::Start>


=back


=head1 Call for Contributions

This project needs contributions from Programmers and Mathematicians. Review and citations from Mathematicians are urgently requested, because in addition to being a Tool-set for implementing vote counting this documentation will for many also be the manual. From coders there is a lot of help that could be given: any well known method could use a write up if it is easy to implement with the toolkit (see Benham) or a code submission if it is not. Currently Tiedeman, SSD, and Kemmeny-Young are unimplemented.


=head1 Advice, Recommendations, Opinion

This section is highly opinionated by the Author of Vote::Count.

If you're looking at all of this wondering "which method I should recommend to my organization to implement Ranked Choice Voting internally?" this is the advice offered by the author of Vote::Count.

I<Instant Runoff Voting> is simple, easy to count by hand, Later Harm protected, and is the most widely used method. It has serious consistency issues, especially how poorly it handles common cloning situations.

I<Benham Condorcet IRV>, meets the two main Condorcet Criteria, and is countable by hand, but it fails Later Harm.

Benham and IRV are good choices for Hand Count Methods.

I<Smith Set IRV> meets all three key criteria for Condorcet Methods and has less Later Harm effect than any other (non-redacting) Condorcet Method. It is simple to understand, but not practical for hand counting.

If you like I<Borda> or prefer a I<Range Ballot>, my pick is for I<STAR>.

STAR is handcountable but requires a Range Ballot. Range methods like STAR have less Later Harm effect than Borda Methods.

I<Redacting Condorcet Methods> are the B<best> for a conventional Ranked Choice Ballot. If a Condorcet Winner does not create a Later Harm violation they will always be chosen. They can create a gauge of the later harm effect that then allows for the establishment of a Later Harm tolerance. The steps for I<Condorcet Vs IRV> are easy to understand but the number of steps qualifies it as somewhat complex. Other methods in the family (not yet implemented) will be more complex.

B<Redacting Condorcet> (Condorcet Vs IRV being the only one available here at the moment) is my preference. B<STAR> is my preferred Scoring method. If you need to hand count, Benham is your Condorcet Method and IRV is your Later Harm Protected Method. Smith Set IRV is a simple Condorcet Method that is better on Later Harm than any other non-redacting Condorcer Method, it is a much better choice than Benham. If Later Harm compliance is required a Redacting Condorcet Method is your best choice, and IRV your choice if they're too complex.


=head2 Floor Rules and Tie Breakers

In real world elections it is typical to have a number of choices that recieve very little support. A Floor Rule allows quick elimination of these choices, but don't help when voters rank all choices. STAR is an exception and does not benefit from a Floor Rule. 5% Approval is a good weak Floor, and TCA is a good aggressive one.

Ties are inescapable. Modified Grand Junction has the maximum resolvability, but has a Later Harm effect. For a Later Harm safe Tie Breaker Eliminate All is effective (except at the final step).

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