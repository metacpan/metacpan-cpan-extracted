# Multi Member

Multi Member Elections can be a good way of obtaining proportionality or at least minority representation. Instead of electing one representative for a seat, several are chosen.

## Vote for One

Voters each pick one choice and the top choices are chosen to fill the seats. Depending on the number of seats and the distribution of factions this can be very inefficient and force voters to attempt to coordinate their votes. If there are three seats and one faction has more than 2/3 of the support, the large faction needs to offer two choices and make sure their votes are split evenly between the two.

## Approval, Cumulative Approval and X of Y

Approval is a better method and is used in a lot of places. Voters mark as many choices as they please, and the seats are filled by the top vote getters. Approval has problems with Bullet Voting and with factions being able to coordinate their vote, such that the largest coordinated faction can take all of the seats. Cumulative Approval gives the voter a fixed number of votes that they can distribute among choices.

X of Y is an improvement of Approval that restricts the number of choices parties can offer and the number of choices a voter can select. Vote for up to X choices, but Y choices will be elected. This method can be used to guarantee minority seats in a body, but will not efficiently allocate those seats. X of Y is tabulated in the same manner as Approval.

## Single Transferable Vote (STV)

Most of the discussion on Multi Member methods focuses on this group.

### Generalized Description of STV

STV uses a Ranked Ballot.

A quota based on the number of valid ballots is set, usually __1 + ( Ballots ÷ ( Number of Choices + 1 ) )__.

The highest choice (plurality) that exceeds the quota is elected. The amount by which the choice exceeded the quota is the Surplus, this is redistributed to the next highest choice on the ballot. This is where the methods diverge, some older methods randomly picks ballots to redistribute, but all current methods split the ballots.

If no choice reaches the quota, the lowest choice is eliminated and their ballots are redistributed.

The Vote::Count STV template also elects all remaining choices in the event that eliminating a choice would make it impossible to fill all of the seats.

## Vote Charging

Vote Charging is mathematically equivalent to Surplus Transfer, but is simpler to explain. Each Vote is treated like a roll of pennies. When a choice reaches the STV quota, the votes are charged. In future iterations the ballots are weighted by their remaining value.



## Scoring

With Approval, Ranked or Range Ballots each possible outcome of the election can be used to generate scores based on the voter preferences, the outcome generating the highest score is chosen.

Scoring encounters the same weighting issues as Borda Count does.

## Multi Member Methods Implementation and Status

| Method | Implementation |
|:------------- |:-----|
| Vote For One | [Vote::Count::TopCount](https://metacpan.org/pod/Vote::Count::TopCount) |
| Approval | [Vote::Count::Approval](https://metacpan.org/pod/Vote::Count::Approval) |
| X of Y | [Vote::Count::Approval](https://metacpan.org/pod/Vote::Count::Approval) |
| Cumulative Approval | *Unimplemented* |
| STV methods with Random | won't implement random in Vote::Count |
| STV: ERS97 | unimplemented |
| STV: Scottish | unimplemented |
| STV: Meek | unimplemented |
| Vote Charging | unimplemented |
| Scoring | unimplemented |