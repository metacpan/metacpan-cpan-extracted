# ABSTRACT: Catalog of Voting Methods and their Vote::Count Implementations

# NAME

Catalog

# Description

A catalog of common Vote Counting Systems and their implementation in Vote::Count.

# Methods by Family

## Borda Count

The Borda Count implementation does not yet cover all common weighting rule variations.

* Borda Count: core [Vote::Count::Borda](https://metacpan.org/pod/Vote::Count::Borda)
* Nansen: *needs example*
* Baldwin: *needs example*
* Minet: *needs example*
* STAR: [Vote::Count::Method::STAR](https://metacpan.org/pod/Vote::Count::Method::STAR)

## Instant Runoff Voting

* Instant Runoff Voting: core [Vote::Count::IRV](https://metacpan.org/pod/Vote::Count::IRV)
* Benham Condorcet IRV: [Hand Count](https://metacpan.org/pod/release/BRAINBUZ/Vote-Count/Hand_Count.pod) methods documentation, implemented by [Vote::Count::Method::CondorcetDropping](https://metacpan.org/pod/Vote::Count::Method::CondorcetDropping)
* SmithSet IRV: [Vote::Count::Method::CondorcetIRV](https://metacpan.org/pod/Vote::Count::Method::CondorcetIRV)

## Condorcet

### Simple Condorcet

* Benham Condorcet IRV: [HandCount](https://metacpan.org/pod/release/BRAINBUZ/Vote-Count/Hand_Count.pod) methods documentation, implemented by [Vote::Count::Method::CondorcetDropping](https://metacpan.org/pod/Vote::Count::Method::CondorcetDropping)
* Simple Dropping: [Vote::Count::Method::CondorcetDropping](https://metacpan.org/pod/Vote::Count::Method::CondorcetDropping)
* SmithSet IRV: [Vote::Count::Method::CondorcetIRV](https://metacpan.org/pod/Vote::Count::Method::CondorcetIRV)

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

Copyright 2019 by John Karr (BRAINBUZ) brainbuz@cpan.org.

# LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit http://fsf.org.
