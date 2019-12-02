# ABSTRACT: Hand Count Methods and Vote::Count

# NAME

Hand_Count_Methods

# Description

Documentation on Hand Counting Elections and the Vote::Count equivalents.

# Instant Runoff Voting

IRV is extremely easy to handcount.

* Stack the Ballots by Top Choice

* Count the stacks

* Elect a Majority Winner

* If there is no Winner, eliminate the low choice, distribute the Ballots to the new Top Choice. Either re-count the stacks or add the number of Ballots being added to the stack in the tally.

In the event of ties the default for Vote::Count is Eliminate All.

Implemented in [Vote::Count::IRV](https://metacpan.org/pod/Vote::Count::IRV).

# Condorcet

It is easy to create pairings by hand. With a larger field the work to fill out the matrix becomes extensive. To reduce the Matrix as much as possible, Hand Count Condorcet Methods should use the TCA Floor Rule (see the Floor module), unless voters will be marking all choices (in which case Floor rules have no effect).

If a method only seeks a Condorcet Winner, a significantly smaller number of pairings is needed. A 10 choice election requires 45 pairings, a method that seeks only a Condorcet Winner can find the Condorcet Winner or determine there is none in as little as 9 pairings.

The best known Condorcet Hand Count method is Benham.

## Benham Condorcet IRV

Returns the winner as soon as there is a Majority Winner or one of the choices is shown to be a Condorcet Winner. Because it is not necessary to produce a full matrix this method is easier to count than other Pairwise Condorcet Methods.

## Criteria

## Simplicity

Benham is easy to understand and is handcountable.

## Later Harm

Benham has less Later Harm effect than many Condorcet Methods, but not a lot less.

## Condorcet Criteria

Meets Condorcer Winner and Loser, fails the Smith Criteria.

## Consistency

In so far as Benham will always elect a Condorcet Winner if present it is more consistent than IRV, when none is present it shares the consistency weaknesses of IRV.

## Benham Handouct Process

* Top Count the Ballots

* Elect a Majority Winner

* Start a sheet for each choice with a Wins and Losses Column. If you also count Approval, for each choice with lower Approval than the Top Count of another choice you can immediately mark the resolutions on the sheets.

* Then starting with the Top Count Leader compare them to the next highest choice (that they haven't already been paired to) and pair them off, recording the result on the sheets.

* Continue pairing the winner of the contest to the next choice.

* The next choice will be the highest Top Count that has not yet been in a pair. If all choices have been paired, it is the highest Top Count not yet paired with the other choice you have.

* When a Condorcet Winner is found they are the Winner.

* When all choices have a loss there is no Condorcet Winner.

* If no Condorcet Winner is found, then remove the choice with the lowest Top Count. Repeat the search for a Condorcet Winner, now ignoring losses to eliminated choices. If no Condorcet Winner remove the choice with the lowest Top Count, repeating the process until there is a winner.

## Implementation in Vote::Count

An equivalent to Benham can be implemented easily through Vote::Count::CondorcetDropping.

  use Vote::Count::CondorcetDropping;
  my $Benham =
    Vote::Count::Method::CondorcetDropping->new(
      'BallotSet' => read_ballots('myballots'),
      'DropStyle' => 'all',
      'DropRule'  => 'topcount',
      'SkipLoserDrop' => 1
    );
  my $Result = $Benham->RunCondorcetDropping();

Implemented in [Vote::Count::Method::CondorcetDropping](https://metacpan.org/pod/Vote::Count::Method::CondorcetDropping).

## Note

The original method specified Random as a Tie Breaker, this has the advantage of making the system fully resolvable, but at the extreme Consistency expense of making it possible to get different results with the same ballots.

Your Election Rules should specify a tiebreaker, the default is Eliminate All; the modified Grand Junction Tie Breaker provides the maximum possible resolvability.

# Borda

* Count the number of first, second, and so on votes for the choices.
* If unranked choices have a default rank other than 0, make sure to tally the values for unranked choices. (Currently Vote::Count only implements 0)
* Determine the weight, unless the weighting is fixed it will change with the number of choices.
* Multiply the weight of each ranking times the number of votes and total these scores for each choice.
* Highest Score Wins.

Beware of variations in weighting rules.

Implemented in [Vote::Count::Borda](https://metacpan.org/pod/Vote::Count::Borda).

# STAR (Score Then Automatic Runoff)

STAR is counted the same way as Borda, with two changes.

The weighting is determined by the voter on the Range Ballot, unranked choices are scored as 0.

The two highest scoring choices are then placed into an automatic runoff. Count the top choice between the runoff choices. Ballots which rank neither or rank them both at the same value are ignored.

Implemented in [Vote::Count::Method::STAR](https://metacpan.org/pod/Vote::Count::Method::STAR).
