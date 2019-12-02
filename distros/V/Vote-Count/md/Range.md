# Range (Score) Voting Overview

Range or Score Voting is another form of preferential ballot.

* There are a fixed number of Rankings available, usually 5, 10 or 100.

* Voters (Typically) May Rank Choices Equally.

* Voters Rank their best choice highest, the inverse of Ranked Choice.

Range Voting is usually resolved by using the ratings assigned by the voters as a score. By fixing the number of available rankings it resolves Borda Count's weighting problem. Condorcet can resolve Range Voting, but the ability to rank choices equally increases the possibility of ties. When resolving by IRV it is necessary to split the vote for equally ranked choices.

# Reading Range Ballots

See [Vote::Count::ReadBallots](https://metacpan.org/pod/Vote::Count::ReadBallots)

# Range Methods

## Score

Score is a method provided by [Vote::Count::Score](https://metacpan.org/pod/Vote::Count::Score) that will score the ballots based on the scores provided by the voters.

## STAR (Score Then Automatic Runoff)

Creates a runoff between the top 2 choices. Implemented in [Vote::Count::Method::STAR](https://metacpan.org/pod/Vote::Count::Method::STAR).

## Condorcet

[Vote::Count::Matrix](https://metacpan.org/pod/Vote::Count::Matrix) supports Range Ballots. Choices scored equally are not counted in pairings between the equal choices.

## IRV

[Vote::Count::IRV](https://metacpan.org/pod/Vote::Count::IRV) supports Range Ballots. Equal Scores are split. The split votes are tabulated with Rational Number Math to protect against rounding errors.

## Tie Breakers

Only Approval, all and none currently supports Range Ballots.

# Ordinal Ranged

Limiting voters to one choice per Rank has the advantage of creating a ballot which translates perfectly to Ranked Choice ballots. From an analysis standpoint having such versatile ballots is valuable. While IRV and Condorcet work with Range Ballots, they work better with Ordinal Ballots, where Scoring Methods works much better with Range ballots. As alternate ballots gain popularity the ability to compare the results across methods with the same live data will be valuable.

Unfortunately limiting the number of choices is also limiting the voter's expression. The larger the Range the less this issue matters. On a Range 100 ballot it is unlikely that in a real world situation a voter is going to be able to or want to rank nearly that many. Because the Range needs space to express strong and weak preference 10 is the minimum reasonable size.
