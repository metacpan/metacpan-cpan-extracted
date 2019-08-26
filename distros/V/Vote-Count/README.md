# Vote::Count

## A Toolkit for determining the outcome of Ranked Choice and other Alternative Balloting Strategies.

Provides a Toolkit for implementing multiple voting systems, allowing a wide range of method options. This library allows the creation of election resolution methods matching a set of Election Rules that are written in an organization's governing rules, and not requiring the bylaws to specify the rules of the software that will be used for the election, especially important given that many of the other libraries available do not provide a bylaws compatible explanation of their process.

This is also extremely useful to researchers who may want to study multiple methods and variations of methods.

# Synopsis

  use 5.022; # Minimum Perl, or any later Perl.
  use feature qw /postderef signatures/;

  use Vote::Count;
  use Vote::Count::ReadBallots 'read_ballots';
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
  say '******************';
  say "Plurality Winner: $PluralityWinner->{'winner'}";
  say "IRV Winner: $IRVResult->{'winner'}";
  say "Winner: $Winner";

# Preview Release

This module is not ready for production. 

# Overview

## Brief Review of Voting Methods

Several alternatives have been proposed to the simple vote for a single choice method that has been used in most elections for a single member. In addition a number of different methods have been used for multiple members. For alternative single member voting, the three common alternatives are *Approval* (voters indicate all choices that they approve of), *Ranked Choice* (Voters rank the choices), and *Score* also known as *Range* (A Ranked Choice Ballot where the number of rankings is limited but voters may rank more than 1 choice at each rank).

*Vote for One* ballots may be resolved by one of two methods: *Majority* and *Plurality*. Majority vote requires a majority of votes to win (but frequently produces no winner), and Plurality which selects the choice with the most votes.

Numerous methods have been proposed and tried for *Ranked Choice Ballots*. To compare these methods a number of criteria have been developed. While Mathematicians often treat these criteria as absolutes, from a policy perspective it may be more valuable to see them as a spectrum where a method may be considered to satisfy or fail with varying degrees of severity. From a policy perspective it is appropriate to group several of the criteria into a single group: Consistency. Finally typically Mathematicians do not directly consider Complexity, but from a policy perspective this is just as important as any of the other criteria, and is definitely a scale not an absolute.

### The Criteria for Resolving Ranked Choice (including Score) Ballots

#### Later Harm

Marking a later Choice on a Ballot should not cause a Voter's higher ranked choice to lose.

#### Condorcet Criteria

*Condorcet Loser* states that a method should not choose a winner that would be defeated in a direct matchup to all other choices.

*Condorcet Winner* states a choice which defeats all others in direct matchups should be the Winner.

*Smith Criteria* if there is a set of choices which defeats all others in direct matchups the winner should be one of those choices.

#### Consistency Criteria

The Consistency Criteria collectively state: Changes to non-winning alternatives that would not obviously alter the outcome should not change the winner. Adding or removing non-winning choices, or altering the votes for non-winning choices, except in a manner which directly changes the outcome should not alter the outcome. If votes are moved between non-winning alternatives in a manner that has no direct affect on the winner, the winner should not change. Changes to non-winning choices which increase support for the winner should not then cause a different choice to win.

To illustrate inconsistency: suppose every morning we vote on a flavor of Ice Cream and Chocolate always wins; one morning the three voters who always vote 1:RockyRoad 2:Chocolate simply vote for Chocolate, consistency is violated if Chocolate loses on that day.

Cloning occurs when similar choices are available, such as Vanilla and Vanilla Bean. If one of the clones would win without the presence of the other, the presence of both should not cause a non-clone to win.

The cases described above: Monotonocity, Independence of Irrelevant Alternatives and Clone Independence are normally discussed as seperate criteria rather than components of one. Additional sub-criteria that haven't been mentioned include: Reversal Symmetry, Participation Consistency, and Later No Help (which could also be considered a sub-criteria of Later Harm).

#### Complexity

Is it feasible to count 100 ballots by hand? How difficult is it to understand the process (can the average middle school student understand it at all)? How many steps?

#### Resolvability

*Majority* meets all of the above criteria, however, unless votes are restricted to two choices, it will frequently fail to provide a winner, or even a tie. No method can be completely impervious to ties. Methods that are not Resolvable are frequently combined with other methods, *Instant Runoff Voting* is a compound method with *Majority*, and all usable *Condorcet* Methods combine seeking a Condorcet Winner with some other process.

#### Incentive for Strategic Voting

Voting systems have weaknesses which can incentivize voter to vote in an insincere manner. Later Harm Violation is a strong driver for tactical voting. Inconsistency may create circumstances by which a block of voters by voting in certain ways can boost or harm a choice, this vulnerability type is often referred to as an attack, because successful exploitation violates the expectation that all voters have an equal impact on the outcome.

### Arrow's Theorem

Arrows Theorem states that it is impossible to have a system that can resolve Ranked Choice Ballots which meets Later Harm and Condorcet Winner. To extend the notion, if it is impossible to meet two criteria it is truly impossible to meet five. Every method  has a trade off, where it will fail some criteria and fail them to different degrees.

### Popular Ranked Choice Resolution Systems

#### Instant Runoff Voting (IRV also known as Alternative Vote)

Seeks a Majority Winner. If there is none the lowest choice is eliminated until there is a Majority Winner or all remaining choices have the same number of votes.

* Easy to Hand Count and Easy to Understand.
* Meets Later Harm.
* Fails Condorcet Winner (but meets Condorcet Loser).
* Fails many Consistency Criteria (The example given for Consistency can happen with IRV). IRV handles clones poorly.

#### Borda Count

Scores choices on a ballot based on their position. Borda supporters often disagree about the weighting rule to use in the scoring. Iterative Borda Methods (Baldwin, Nansen) eliminate the lowest choice(s) and recalculate the Borda score ignoring  eliminated choices (if your second choice is eliminated your third choice is promoted).

* Easy to Understand.
* Fails Later Harm.
* Fails Condorcet Winner.
* Inconsistant.
* The basic Borda Method is vulnerable to a Cloning Attack.

#### Condorcet

Technically this family of methods should be called Condorcet Pairwise, because any method that meets both Condorcet Criteria is technically a Condorcet Method. However, in discussion and throughout this software collection the term Condorcet will refer to  methods which uses a Matrix of Wins and Losses derived from direct pairing of choices and seeks to identify a Condorcet Winner.

The basic Condorcet Method will frequently fail to identify a winner. One possibility is a Loop (Condorcet's Paradox) Where A > B, B > C, and C > A. Another possibility is a knot (not an accepted term, but one which will be used in this documentation). To make Condorcet resolvable a second method is typically used to resolve Loops and Knots.

* Complexity Varies among sub-methods.
* Fails Later Harm.
* Meets both Condorcet Criteria.
* When a Condorcet Winner is present Consistency is met. When there is no Condorcet Winner this Consistency also applies between a Dominant (Smith) Set and the rest of the choices, but not within the Smith Set. Sub-methods vary in consistency when there is no Condorcet Winner.

### Score (Range) Voting Systems

Most Methods for Ranked Choice Ballots can be used for Score Ballots, either directly or by translating the ballots. Score Voting proposals typically implement *Borda Count*, with a fixed depth of choices. *STAR*, creates a virtual runoff between the top two *Borda Count* Choices.

Advocates of Score Voting claim that this Ballot Style is a better expression of voter preference (which is purely a matter of opinion and cannot be proved or disproved), but it does create more potential for ties in the resolution process than RC does (which is a reason to assert RC is better). 

Borda appears to benefit from a switch to Score Ballots, while IRV and Condorcet are better served by Ranked Ballots.

# Objective and Motivation

I wanted to be able to evaluate alternative methods for resolving elections and couldn't find a flexible enough existing libary in any of the popular general purpose and web development languages: Perl, PHP, Python, Ruby, JavaScript, nor in the newer language Julia (created as an alternative to R and other math languages). More recently I was writing a bylaws proposal to use RCV and found that the existing libraries and services were not only constrained in what options they can provide, but also didn't always document them clearly, making it a challenge to have a method described in bylaws where it could be guaranteed hand and machine counts would agree.

The objective is to have a library that can handle any of the myriad variants that one might consider either from a study perspective or what is called for by the elections rules of our entity.

# Basics

## Reading Ballots

The Vote::Count::ReadBallots library provides functionality for reading files from disc. Currently it defines a format for a ballot file and reads that from disk. In the future additional formats may be added.

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

Active sets are typically represented as a Hash Reference where the keys represent the active choices, the values are ignored. The VoteCount Object contains an Active Set which can be Accessed or set via the ->Active() method. The ->GetActive and ->SetActive methods are preferred because they break the reference link between the object's copy and the external copy of the Active set.

Most Components will take an argument for $activeset or default to the current Active set of the Vote::Count object, which will default to the Choices defined in the BallotSet.

# Vote::Count Methods

* new

* Active: Set or Get Active Set as HashRef

* BallotSet: Get BallotSet

* BallotSetType: Get the BallotSet Type (not implemented)

* PairMatrix: Get a Matrix Object for the Active Set. Generated and cached on the first request.

* UpdatePairMatrix: Regenerate and cache Matrix with current Active Set.

* VotesCast: Returns the number of votes cast.

## Components

### Consumed As Roles By Vote::Count

  * [Vote::Count::Approval](https://metacpan.org/pod/Vote::Count::Approval)
  * [Vote::Count::Borda](https://metacpan.org/pod/Vote::Count::Borda)
  * [Vote::Count::Floor](https://metacpan.org/pod/Vote::Count::Floor)
  * [Vote::Count::TopCount](https://metacpan.org/pod/Vote::Count::TopCount)
  * [Vote::Count::Redact](https://metacpan.org/pod/Vote::Count::Redact)
  * [Vote::Count::TieBreaker](https://metacpan.org/pod/Vote::Count::TieBreaker)

### Return Their Own Objects

  * [Vote::Count::Matrix](https://metacpan.org/pod/Vote::Count::Matrix)
  * [Vote::Count::RankCount](https://metacpan.org/pod/Vote::Count::RankCount)

### Voting Methods

  * [Vote::Count::Method::CondorcetDropping](https://metacpan.org/pod/Vote::Count::Method::CondorcetDropping)
  * [Vote::Count::Method::IRV](https://metacpan.org/pod/Vote::Count::Method::IRV)

### Non Object Oriented Components

  * [Vote::Count::Redact](https://metacpan.org/pod/Vote::Count::Redact)

### Utilities

  * [Vote::Count::ReadBallots](https://metacpan.org/pod/Vote::Count::ReadBallots)
  * [Vote::Count::Start](https://metacpan.org/pod/Vote::Count::Start)  

### Documentation

Additional Documentation Files

* [Vote::Count::HandCount](https://metacpan.org/pod/distribution/Vote-Count/lib/Vote/Count/Method/HandCount.pod)
* [Vote::Count::Start](https://metacpan.org/pod/Vote::Count::Start)  


# Call for Contributions

This project needs contributions from Programmers and Mathematicians. Review and citations from Mathematicians are urgently requested, because in addition to being a Tool-set for implementing vote counting this documentation will for many also be the manual. From coders there is a lot of help that could be given: any well known method could use a write up if it is easy to implement with the toolkit (see Benham) or a code submission if it is not. Currently Tiedeman, SSD, and Kemmeny-Young are unimplemented. In addition support for Range Ballots will require significant effort.

# Advice, Recommendations, Opinion

This section is highly opinionated by the Author of Vote::Count.

If you're looking at all of this wondering "which method I should recommend to my organization to implement Ranked Choice Voting internally?" this is the advice offered by the author of Vote::Count.

*Instant Runoff Voting* is simple, easy to count by hand, Later Harm protected, and is the most widely used method. It has serious consistency issues, especially how poorly it handles common cloning situations.

*Benham Condorcet IRV*, meets the two main Condorcet Criteria, and is countable by hand, but it loses Later Harm.

If you like *Borda* or prefer a *Range Ballot*, my pick is for *STAR*. STAR specifies a Range Ballot. Range Ballots are not presently implemented, and will require a lot of work, so it may be some time before it's available here. In the meantime you can implement the RCV variant of STAR with Vote::Count.

*SmithSet IRV*, is the **best simple method**. It meets all three key criteria for Condorcet Methods and has less Later Harm effect than any other (non-redacting) Condorcet Method.

*Redacting Condorcet Methods* are the **best**. If a Condorcet Winner does not create a Later Harm violation they will always be chosen. They can create a gauge of the later harm effect that then allows for the establishment of a Later Harm tolerance. If there is a Later Harm violation, then ballots are redacted, and the resulting final ballots will meet the Condorcet Criteria.

## Always Pick a Floor Rule

Unless your voting rules require voters to rank all choices, a good floor rule will quickly eliminate the low support choices.
