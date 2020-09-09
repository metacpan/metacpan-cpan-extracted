# Vote::Count

## A Toolkit for determining the outcome of Preferential Ballots.

Provides a Toolkit for implementing multiple voting systems, allowing a wide range of method options. This library allows the creation of election resolution methods matching a set of Election Rules that are written in an organization's governing rules, and not requiring the bylaws to specify the rules of the software that will be used for the election, especially important given that many of the other libraries available do not provide a bylaws compatible explanation of their process.

# Synopsis

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
  $CondorcetElection->SetActive( $ChoicesAfterFloor );
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

# Overview

## Brief Review of Voting Methods

Several alternatives have been proposed to the simple vote for a single choice method that has been used in most elections for a single member. In addition a number of different methods have been used for multiple members. For alternative single member voting, the three common alternatives are *Approval* (voters indicate all choices that they approve of), *Ranked Choice* (Voters rank the choices), and *Score* also known as *Range* (voters give choices a score according to a scale).

*Vote for One* ballots may be resolved by one of two methods: *Majority* and *Plurality*. Majority vote requires a majority of votes to win (but frequently produces no winner), and Plurality which selects the choice with the most votes.

Numerous methods have been proposed and tried for *Ranked Choice Ballots*. To compare these methods a number of criteria have been developed. While Mathematicians often treat these criteria as absolutes, from a policy perspective it may be more valuable to see them as a spectrum where a method may be considered to satisfy or fail with varying degrees of severity. From a policy perspective it is appropriate to group most of the criteria into a single group: Consistency. Finally Mathematicians, typically, do not directly consider Complexity, but from a policy perspective this is just as important as any of the other criteria, and is definitely a scale not an absolute.

### The Criteria for Resolving Ranked Choice (including Score) Ballots

#### Later Harm

Marking a later Choice on a Ballot should not cause a Voter's higher ranked choice to lose.

#### Condorcet Criteria

*Condorcet Loser* states that a method should not choose a winner that would be defeated in a direct matchup to all other choices.

*Condorcet Winner* states a choice which defeats all others in direct matchups should be the Winner.

*Smith Criteria* the winner should belong to the smallest set of choices which defeats all choices outside of that set.

#### Consistency Criteria

The Consistency Criteria collectively state: Changes to non-winning alternatives that would not obviously alter the outcome should not change the winner. Adding or removing non-winning choices, or altering the votes for non-winning choices, except in a manner which directly changes the outcome should not alter the outcome. If votes are moved between non-winning alternatives in a manner that has no direct affect on the winner, the winner should not change. Changes to non-winning choices which increase support for the winner should not then cause a different choice to win.

To illustrate inconsistency: suppose every morning we vote on a flavor of Ice Cream and Chocolate always wins; one morning the three voters who always vote 1:RockyRoad 2:Chocolate simply vote for Chocolate, consistency is violated if Chocolate loses on that day.

Cloning occurs when similar choices are available, such as Vanilla and Vanilla Bean. If one of the clones would win without the presence of the other, the presence of both should not cause a non-clone to win.

The cases described above: Monotonocity, Independence of Irrelevant Alternatives and Clone Independence are normally discussed as separate criteria rather than components of one. Additional sub-criteria that haven't been mentioned include: Reversal Symmetry, Participation Consistency, and Later No Help (which could also be considered a sub-criteria of Later Harm).

There is a specific Criteria that is sometimes called Consistency, in this discussion consistency is discussed in the broad context. No method passes every possible consistency criteria, from a policy perspective a method is consistent if it has no major consistency failures.

#### Complexity

Is it feasible to count 100 ballots by hand? How difficult is it to understand the process (can the average middle school student understand it at all)? How many steps?

#### Resolvability

*Majority* meets all of the above criteria, however, unless votes are restricted to two choices, it will frequently fail to provide a winner, or even a tie. No method can be completely impervious to ties. Methods that are not Resolvable are frequently combined with other methods, *Instant Runoff Voting* is a compound method with *Majority*, and all usable *Condorcet* Methods combine seeking a Condorcet Winner with some other process.

#### Incentive for Strategic Voting

Voting systems have weaknesses which can incentivize voters to vote in an insincere manner. Later Harm Violation is a strong driver for tactical voting. Inconsistency may create circumstances by which a block of voters by voting in certain ways can boost or harm a choice, this vulnerability type is often referred to as an attack.

### Arrow's Theorem

Arrows Theorem states that it is impossible to have a system that can resolve Ranked Choice Ballots which meets Later Harm and Condorcet Winner. To extend the notion, if it is impossible to meet two criteria it is truly impossible to meet five. Every method  has a trade off, where it will fail some criteria and fail them to different degrees.

### Popular Ranked Choice Resolution Systems

#### Instant Runoff Voting (IRV is also known as Hare System, Alternative Vote)

Seeks a Majority Winner. If there is none the lowest choice is eliminated until there is a Majority Winner or all remaining choices have the same number of votes.

* Easy to Hand Count and Easy to Understand.
* Meets Later Harm.
* Fails Condorcet Winner (but meets Condorcet Loser).
* Fails many Consistency Criteria (The example given for Consistency can happen with IRV). IRV handles clones poorly.

#### Borda Count and Scoring

When Range (Cardinal) Ballots are used, the scores assigned by the voters are tallied to score the choices.

Since Scoring is native to Range Ballots, to use the approach to resolve Ranked Ballots requires a method of assigning scores.

Borda Count Scores choices on a ballot based on their position. Borda supporters often disagree about the weighting rule to use in the scoring. Iterative Borda Methods (Baldwin, Nansen) eliminate the lowest choice(s) and recalculate the Borda score ignoring eliminated choices (if your second choice is eliminated your third choice is promoted).

* Easy to Understand.
* Fails Later Harm.
* Fails Condorcet Winner.
* Inconsistent.
* The basic Borda Method is vulnerable to a Cloning Attack, but not Range Ballot Scoring and iterative Borda methods.

#### Condorcet

Technically this family of methods should be called Condorcet Pairwise, because any method that meets both Condorcet Criteria is technically a Condorcet Method. However, in discussion and throughout this software collection the term Condorcet will refer to  methods which uses a Matrix of Wins and Losses derived from direct pairing of choices and seeks to identify a Condorcet Winner.

The basic Condorcet Method will frequently fail to identify a winner. One possibility is a Loop (Condorcet's Paradox) Where A > B, B > C, and C > A. Another possibility is a knot (not an accepted term, but one which will be used in this documentation). To make Condorcet resolvable a second method is typically used to resolve Loops and Knots.

* Complexity Varies among sub-methods.

* Fails Later Harm.

* Meets both Condorcet Criteria.

* When a Condorcet Winner is present Consistency is very high. When there is no Condorcet Winner this Consistency applies between a Dominant (Smith) Set and the rest of the choices, but not within the Smith Set. Sub-methods vary in consistency when there is no Condorcet Winner.

### Range (Score) Voting Systems

Most Methods for Ranked Choice Ballots can be used for Range Ballots.

Score Voting proposals typically implement *Borda Count*, with a fixed depth of choices. *STAR*, creates a virtual runoff between the top two *Borda Count* Choices.

Advocates claim that this Ballot Style is a better expression of voter preference. Where it shows a clear advantage is in allowing Voters to directly mitigate Later Harm by ranking a strongly favored choice with the highest score and weaker choices with the lowest. The downside to this strategy is that the voter is giving little help to later choices reaching the automatic runoff. Given a case with two roughly equal main factions, where one faction give strong support to all of its options, and the other faction's supporters give weak support to all later choices; the runoff will be between the two best choices of the first faction, even if the choices of the second faction all defeat any of the first's choices in pairwise comparison.

The Range Ballot resolves the Borda weighting problem and allows the voter to manage the later harm effect, so it is clearly a better choice than Borda. Condorcet and IRV can resolve Range Ballots, but ignore the extra information and would prefer strict ordinality (not allowing equal ranking).

Voters may find the Range Ballot to be more complex than the Ranked Choice Ballot.

# Objective and Motivation

I wanted to be able to evaluate alternative methods for resolving elections and couldn't find a flexible enough existing library in any of the popular general purpose and web development languages: Perl, PHP, Python, Ruby, JavaScript, nor in the newer language Julia (created as an alternative to R and other math languages). More recently I was writing a bylaws proposal to use RCV and found that the existing libraries and services were not only constrained in what options they can provide, but also didn't always document them clearly, making it a challenge to have a method described in bylaws where it could be guaranteed hand and machine counts would agree.

The objective is to have a library that can handle any of the myriad variants that one might consider either from a study perspective or what is called for by the elections rules of our entity.

# Basics

## Reading Ballots

The [Vote::Count::ReadBallots](https://metacpan.org/pod/Vote::Count::ReadBallots) library provides functionality for reading files from disc. Currently it defines a format for a ballot file and reads that from disk. In the future additional formats may be added. Range Ballots may be in either JSON or YAML formats.

## Voting Method and Component Modules

The Modules in the space Vote::Count::%Component% provide functionality needed to create a functioning Voting Method. Many of these are consumed as Roles by the Vote::Count object, some such as RankCount and Matrix return their own objects.

The Modules in the space Vote::Count::Method::%Something% implement a Voting Method such as IRV. These Modules inherit the parent Vote::Count and all of the Components available to it. These modules all return a Hash Reference with the following key: *winner*, some return additional keys. Methods that can be tied will have additional keys *tie* and *tied*. When there is no winner the value of *winner* will be false.

Simpler Methods such as single iteration Borda or Approval can be run directly from the Vote::Count Object.

## Vote::Count Module

The Core Module requires a Ballot Set (which can be obtained from ReadBallots).

  my $Election = Vote::Count->new(
      BallotSet => read_ballots( 'ballotfile'), # imported from ReadBallots
      ActiveSet => { 'A' => 1, 'B' => 1, 'C' => 1 }, # Optional
  );

### Optional Paramters to Vote::Count

#### Active

A Hashref with the active choices as keys. The Active Choices are represented by a Hashref because it is easier to manipulate hash keys than it is to manipulate random array elements.

#### LogTo

Sets a path and Naming pattern for writing logs with the WriteLogs method.

  'LogTo' => '/logging_path/election_name'

The WriteLogs method will write the logs appending '.brief', '.full', and '.debug' for the three logs where brief is a summary written with the logt (log terse) method, the full transcript log written with logv, and finally the debug log written with logd. Each higher log level captures all events of the lower log levels.

The default log location is '/tmp/votecount'.

When logging from your methods, use logt for events that produce a summary, use logv for events that should be in the full transcript such as round counts, and finally debug is for events that may be helpful in debugging but which should not be in the transcript.

### Active Sets

Active sets are typically represented as a Hash Reference where the keys represent the active choices and the value is true. The VoteCount Object contains an Active Set which can be Accessed via the Active() method which will return a reference to the Active Set (changing the reference will change the active set). The GetActive and SetActive methods do not preserve any reference links and should be preferred. GetActiveList returns the Active Set as a sorted list.

Many Components will take an argument for $activeset or default to the current Active set of the Vote::Count object, which will default to the Choices defined in the BallotSet.

# Vote::Count Methods

Most of these are provided by the Role Common and available directly in both Matrix objects and Vote::Count Objects. Vote::Count objects create a child Matrix object: PairMatrix.

### new

### Active

Get Active Set as HashRef to the active set. Changing the new HashRef will change the internal Active Set, GetActive is recommended as it will return a HashRef that is a copy instead.

### GetActive

Returns a hashref containing a copy of the Active Set.

### GetActiveList

Returns a simple array of the members of the Active Set.

### ResetActive

Sets the Active Set to the full choices list of the BallotSet.

### SetActive

Sets the Active Set to provided HashRef. The values to the hashref should evaluate as True.

### SetActiveFromArrayRef

Same as SetActive except it takes an ArrayRef of the choices to be set as Active.

### BallotSet

Get BallotSet

### PairMatrix

Get a Matrix Object for the Active Set. Generated and cached on the first request.

### UpdatePairMatrix

Regenerate and cache Matrix with current Active Set. 

### VotesCast

Returns the number of votes cast.

### VotesActive

Returns the number of non-exhausted ballots based on the current Active Set.

# Minimum Perl Version

It is the policy of Vote::Count to only develop with recent versions of Perl. Support for older versions will be dropped as they either start failing tests or impair adoption of new features. 

## Components

### Catalog of Methods

Directory of Vote Counting Methods linking to the Vote::Count module for it.

  * [Catalog](https://metacpan.org/pod/distribution/Vote-Count/lib/Vote/Catalog.pod)
  
### Consumed As Roles By Vote::Count

  * [Vote::Count::Approval](https://metacpan.org/pod/Vote::Count::Approval)
  * [Vote::Count::Borda](https://metacpan.org/pod/Vote::Count::Borda)
  * [Vote::Count::Floor](https://metacpan.org/pod/Vote::Count::Floor)
  * [Vote::Count::IRV](https://metacpan.org/pod/Vote::Count::IRV)
  * [Vote::Count::TopCount](https://metacpan.org/pod/Vote::Count::TopCount)
  * [Vote::Count::Redact](https://metacpan.org/pod/Vote::Count::Redact)
  * [Vote::Count::Score](https://metacpan.org/pod/Vote::Count::Score)
  * [Vote::Count::TieBreaker](https://metacpan.org/pod/Vote::Count::TieBreaker)

### Return Their Own Objects

  * [Vote::Count::Matrix](https://metacpan.org/pod/Vote::Count::Matrix)
  * [Vote::Count::RankCount](https://metacpan.org/pod/Vote::Count::RankCount)

### Voting Methods

  * [Vote::Count::Method::CondorcetDropping](https://metacpan.org/pod/Vote::Count::Method::CondorcetDropping)
  * [Vote::Count::Method::CondorcetIRV](https://metacpan.org/pod/Vote::Count::Method::CondorcetIRV)
  * [Vote::Count::Method::CondorcetVsIRV](https://metacpan.org/pod/Vote::Count::Method::CondorcetVsIRV)
  * [Vote::Count::Method::MinMax](https://metacpan.org/pod/Vote::Count::Method::MinMax)  
  * [Vote::Count::Method::STAR](https://metacpan.org/pod/Vote::Count::Method::STAR)

### Non Object Oriented Components

  * [Vote::Count::Redact](https://metacpan.org/pod/Vote::Count::Redact)

### Utilities

  * [Vote::Count::ReadBallots](https://metacpan.org/pod/Vote::Count::ReadBallots)
  * [Vote::Count::Start](https://metacpan.org/pod/Vote::Count::Start)

### Additional Documentation

* [Catalog](https://metacpan.org/pod/distribution/Vote-Count/lib/Vote/Catalog.pod)
* [Hand Count](https://metacpan.org/pod/distribution/Vote-Count/lib/Vote/Hand_Count.pod)
* [Multi Member](https://metacpan.org/pod/distribution/Vote-Count/lib/Vote/MultiMember.pod)
* [Vote::Count::Start](https://metacpan.org/pod/Vote::Count::Start)

# Call for Contributions

This project needs contributions from Programmers and Mathematicians. Review and citations from Mathematicians are urgently requested, because in addition to being a Tool-set for implementing vote counting this documentation will for many also be the manual. From coders there is a lot of help that could be given: any well known method could use a write up if it is easy to implement with the toolkit (see Benham) or a code submission if it is not. Currently Tiedeman, SSD, and Kemmeny-Young are unimplemented.
