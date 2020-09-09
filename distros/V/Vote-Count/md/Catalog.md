# ABSTRACT: Catalog of Voting Methods and their Vote::Count Implementations

# NAME

Catalog

# Description

A catalog of common Vote Counting Systems and their implementation in Vote::Count.

# Methods by Family

## Borda Count

And other Methods which assign scores to choices by their ranking. 

* Borda Count: core [Vote::Count::Borda](https://metacpan.org/pod/Vote::Count::Borda)
* Nansen: *needs example*
* Baldwin: *needs example*
* STAR: [Vote::Count::Method::STAR](https://metacpan.org/pod/Vote::Count::Method::STAR)

## Instant Runoff Voting

* Instant Runoff Voting: core [Vote::Count::IRV](https://metacpan.org/pod/Vote::Count::IRV)
* Benham Condorcet IRV: [Hand Count](https://metacpan.org/pod/release/BRAINBUZ/Vote-Count/Hand_Count.pod) methods documentation, implemented by [Vote::Count::Method::CondorcetDropping](https://metacpan.org/pod/Vote::Count::Method::CondorcetDropping)
* SmithSet IRV: [Vote::Count::Method::CondorcetIRV](https://metacpan.org/pod/Vote::Count::Method::CondorcetIRV)

## PairWise

### Non Condorcet Pairwise

* MinMax (Opposition) [Vote::Count::Method::MinMax](https://metacpan.org/pod/Vote::Count::Method::MinMax)

### Simple Condorcet

* Benham Condorcet IRV: [HandCount](https://metacpan.org/pod/release/BRAINBUZ/Vote-Count/Hand_Count.pod) methods documentation, implemented by [Vote::Count::Method::CondorcetDropping](https://metacpan.org/pod/Vote::Count::Method::CondorcetDropping)
* Simple Dropping: [Vote::Count::Method::CondorcetDropping](https://metacpan.org/pod/Vote::Count::Method::CondorcetDropping)
* SmithSet IRV: [Vote::Count::Method::CondorcetIRV](https://metacpan.org/pod/Vote::Count::Method::CondorcetIRV)
* MinMax (Winning Votes and Margin) [Vote::Count::Method::MinMax](https://metacpan.org/pod/Vote::Count::Method::MinMax)

### Complex Condorcet

* Condorcet vs IRV: [Vote::Count::Method::CondorcetVsIRV](https://metacpan.org/pod/Vote::Count::Method::CondorcetVsIRV)
* Tiedeman: *unimplemented*
* SSD: *unimplemented*
* Kemmeny-Young: *unimplemented*

### Redacting Condorcet

* Condorcet vs IRV: [Vote::Count::Method::CondorcetVsIRV](https://metacpan.org/pod/Vote::Count::Method::CondorcetVsIRV)

## AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

## CONTRIBUTORS

Copyright 2019, 2020 by John Karr (BRAINBUZ) brainbuz@cpan.org.

# LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit http://fsf.org.
