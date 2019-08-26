# NAME

Catalog

# VERSION 0.022

#ABSTRACT: Catalog and Examples of Common Voting Methods with Vote::Count

# Description

A catalog of common Vote Counting Systems and their implementation in Vote::Count.

# Methods by Family

## Borda Count

As of 0.17 the Borda Count implementation does not yet cover all common weighting rule variations.

* Borda Count: core Vote::Count
* Nansen: *needs example*
* Baldwin: *needs example*
* Minet: *needs example*
* Star: *needs Range Ballot support*

## Instant Runoff Voting

Also known as Alternative Vote.

* Instant Runoff Voting: core Vote::Count
* Benham Condorcet IRV: HandCount methods documentation
* SmithSet IRV: Vote::Count::CondorcetIRV

## Condorcet

### Simple Condorcet

* Benham Condorcet IRV: HandCount documentation
* Simple Dropping: Vote::Count::Method::CondorcetDropping
* SmithSet IRV: Vote::Count::CondorcetIRV

### Complex Condorcet

* Condorcet vs IRV: *Vote::Count::CondorcetIRV -- implementation in progress*
* Tiedeman: *unimplemented*
* SSD: *unimplemented*
* Kemmeny-Young: *unimplemented*

### Redacting Condorcet

* Condorcet vs IRV: *Vote::Count::CondorcetIRV -- implementation in progress*

## AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

## CONTRIBUTORS

Copyright 2019 by John Karr (BRAINBUZ) brainbuz@cpan.org.

# LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit http://fsf.org.
