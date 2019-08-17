# Summary

A compound method based on Instant Runoff Voting restricted to the (Condorcet) Smith Set.

Tests each choice to determine if it could win with ballots redacted of all later selections than it. Each of these choices is a Winnable Choice.

The Winnable Choices are then compared in pairs with the ballots redacted for both choices. If one of the choices wins it is the victor in the paring. Otherwise the choice with the smallest margin in its greatest defeat wins.


A Condorcet-IRV hybrid that selects between Choices which could win the Election by identifying the Winnable option which needs the fewest Later Choices and redacting the final ballots if needed.

The final accepted ballots will meet all three Smith-Condorcet Criteria while the method overall has a low Later Harm impact.

The 'Relaxed' option allows the Condorcet Winner of the original ballots to offset later harm with their margin of victory.


-----

Second level comparisons.

If one of the choices wins the matchup they are the winner.

Else
Condorcet vs IRV winner -- Condorcet Winner's greatest defeat is the later harm cost. With relaxed

------


# Description

A Winnable Alternative is a Choice which wins when protected from Later Harm by redacting later Choices from ballots for that Choice.

If an Alternative is a Condorcet Winner in the original ballots without a Later Harm effect against another Winnable Alternative, that Choice is the Winner. A Majority Winner will always meet this.

If there are multiple Winnable Alternatives, to determine which set of ballots are final, another round of testing is done redacting the ballots in pairs. If in the pair one of the choices wins, give it a point



test with ballots redacted for both choices.

With the (recommended) Later Harm Relaxed option, the pairing is modified by the margin of victory of the pair winner over the pair loser.

The election Method is Condorcet Pairwise with fallback to IRV against the Smith Set.

When the Winner is not a Condorcet Winner in the original ballots, the final ballots are the redacted set. The winner will always be a member of the Smith Set of the final ballots, and in fact of the original ballots as well (the redaction does not change which pairings the choice wins, it potentially changes other pairings).




Winnable Alternatives determines which choices would win if they were protected from Later Harm Effect. This is done by redacting ballots for each choice and conducting an election. When there are multiple Winnable Alternatives it compares the Later Harm Effect to the Margins between the Winnable Choices. The Elections are run using IRV against the Smith Set.
