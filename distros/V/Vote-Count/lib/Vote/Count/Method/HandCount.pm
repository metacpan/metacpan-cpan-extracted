=head1 NAME

Hand Count Methods

=head1 VERSION 0.022

=cut

# ABSTRACT: Documentation about Hand Count Methods

=pod

=head1 Description

Documentation on Hand Counting Elections and the Vote::Count equivalents.

=head1 Instant Runoff Voting

IRV is extremely easy to handcount.

=over

* Stack the Ballots by Top Choice

* Count the stacks

* Elect a Majority Winner

* If there is no Winner, eliminate the low choice, distribute the Ballots to the new Top Choice. Either re-count the stacks or add the number of Ballots being added to the stack in the tally.

=back

In the event of ties the default for Vote::Count is Eliminate All.

=head1 Condorcet

It is easy to create pairings by hand. With a larger field the work to fill out the matrix becomes extensive. To reduce the Matrix as much as possible, Hand Count Condorcet Methods should use the TCA Floor Rule (see the Floor module), unless voters will be marking all choices (in which case Floor rules have no effect).

If a method only seeks a Condorcet Winner, a significantly smaller number of pairings is needed. A 10 choice election requires 45 pairings, a method that seeks only a Condorcet Winner can find the Condorcet Winner or determine there is none in as little as 9 pairings.

The best known Condorcet Hand Count method is Benham.

=head2 Benham Condorcet IRV

Returns the winner as soon as there is a Majority Winner or one of the choices is shown to be a Condorcet Winner. Because it is not necessary to produce a full matrix this method is easier to count than other Pairwise Condorcet Methods.

=head2 Criteria

=head3 Simplicity

Benham is easy to understand and is handcountable.

=head3 Later Harm

Benham has less Later Harm effect than many Condorcet Methods, but not a lot less.

=head3 Condorcet Criteria

Meets Condorcer Winner and Loser, fails the Smith Criteria.

=head3 Consistency

In so far as Benham will always elect a Condorcet Winner if present it is more consistent than IRV, when none is present it shares the consistency weaknesses of IRV.

=head2 Benham Handouct Process

Top Count the Ballots

Elect a Majority Winner

Start a sheet for each choice with a Wins and Losses Column. If you also count Approval, for each choice with lower Approval than the Top Count of another choice you can immediately mark the resolutions on the sheets.

Then starting with the Top Count Leader compare them to the next highest choice (that they haven't already been paired to) and pair them off, recording the result on the sheets.

Continue pairing the winner of the contest to the next choice.

The next choice will be the highest Top Count that has not yet been in a pair. If all choices have been paired, it is the highest Top Count not yet paired with the other choice you have.

When a Condorcet Winner is found they are the Winner.

When all choices have a loss there is no Condorcet Winner.

If no Condorcet Winner is found, then remove the choice with the lowest Top Count. Repeat the search for a Condorcet Winner, now ignoring losses to eliminated choices. If no Condorcet Winner remove the choice with the lowest Top Count, repeating the process until there is a winner.

=head2 Implementation in Vote::Count

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

=head2 Note

The original method specified Random as a Tie Breaker, this has the advantage of making the system fully resolveable, but at the extreme Consistency expense of making it possible to get different results with the same ballots.

Your Election Rules should specify a tiebreaker, the default is Eliminate All; the modified Grand Junction Tie Breaker provides the maximum possible resolvability. [note tie breaker support is a ]

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
