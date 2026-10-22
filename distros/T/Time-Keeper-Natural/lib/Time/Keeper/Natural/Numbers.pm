package Time::Keeper::Natural::Numbers;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.07';

use Time::Keeper::Locale;
use Time::Keeper::Natural ();

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Natural::Numbers - number words from CLDR's spellout rules

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    my $nw = Time::Keeper::Natural::Numbers->for('fr');
    $nw->read('vingt-et-un');          # 21
    $nw->read('vingt et un');          # 21
    $nw->ordinal('troisième');         # 3
    $nw->day('1er');                   # 1
    Time::Keeper::Natural::Numbers->locales;

=head1 DESCRIPTION

The words for the whole numbers 0 to 99, and the ordinals 1 to 31, of the
locales whose CLDR data has spellout rules: about ninety. They are made once,
when the distribution is built, by running CLDR's rules forward
(C<tools/numbercompile>), so every form a locale's rules can write is here,
its genders and cases among them ("одна", "одного", "одной" are all 1), and
nothing that the rules do not write. English adds one hand-written row, "a"
and "an" for 1, so "in a week" reads. The ordinals in digits that a day of
the month is written with, "15th", "1er", "1.º", "第15", come the same way from
the locales' C<%digits-ordinal> rules, with CLDR's ordinal plural rules
deciding "1st" from "11th"; about forty locales have them. A locale with no spellout rules reads
digits only, in any script, as it always did.

A word is read in lower case, with any run of spaces as one, and with its
hyphens or with spaces in their place, so "twenty-one" and "twenty one" are
both 21, and French "vingt-et-un" and "vingt et un" both 21. No other
spelling is read: "vingt-et-un" in the 1990 spelling is what CLDR writes, and
a spelling it does not write is not in the table.

=head1 METHODS

=head2 for

The number words of a locale, from the nearest locale in its chain that has
rules (C<fr-CA> reads C<fr>'s), or C<undef>.

=head2 read

The whole number a text is, 0 to 99, or C<undef>.

=head2 ordinal

The number an ordinal word is, 1 to 31, or C<undef>.

=head2 day

The day of the month a digit ordinal is, 1 to 31 ("15th", "1er"), or
C<undef>.

=head2 cardinals

The words and their numbers, as a list of pairs.

=head2 ordinals

The ordinal words and their numbers.

=head2 days

The digit ordinals and their numbers.

=head2 code

The locale whose rules were read.

=head2 locales

The locales that have number words.

=head2 chain

The codes tried for a locale, its own first.

=head2 dir

Where the words are, one file a locale: beside the module once installed, or
the distribution's C<share/numbers> when run from its tree. A locale with no
file in its chain has no number words, and finding that out reads nothing.

=head1 SEE ALSO

L<Time::Keeper::Natural>, L<Time::Keeper::Natural::Lexicon>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
