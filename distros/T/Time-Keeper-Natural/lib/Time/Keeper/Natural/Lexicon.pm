package Time::Keeper::Natural::Lexicon;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.08';

use Time::Keeper;
use Time::Keeper::Locale;
use Time::Keeper::Natural ();
use Time::Keeper::Natural::Numbers;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Natural::Lexicon - a locale's words for a time, compiled to be read back

=head1 VERSION

Version 0.08

=head1 SYNOPSIS

    use Time::Keeper::Natural::Lexicon;

    my $lex = Time::Keeper::Natural::Lexicon->for('fr');
    $lex->fixed('après-demain');          # { field => 'day', n => 2, width => 'long' }
    $lex->fixed('mardi prochain');        # { field => 'tue', n => 1, width => 'long' }
    $lex->counted('dans 3 semaines');     # { field => 'week', n => 3, count => 3, direction => 1, ... }
    $lex->counted('il y a 21 jours');     # { field => 'day', n => -21, ... }
    $lex->read('hier');                   # fixed and counted together
    $lex->unit('30 minutes');             # { unit => 'minute', n => 30, ... }

=head1 DESCRIPTION

Everything L<Time::Keeper> writes in a locale's words, turned round so that
the words can be read: the relative-time strings of L<Time::Keeper::Locale>
("yesterday", "next Tuesday", "in {0} days", "{0} days ago"), the names of the
weekdays, the months and the parts of a day, and the duration words
("{0} hours"). A lexicon is compiled from the locale data the first time a
locale is asked for and kept.

A text is normalised before it is looked up, and every stored string the same
way: Unicode NFC, typographic apostrophes to the plain one, directional marks
dropped, lower case, any run of spaces to one, and in a locale whose own words
carry no spaces (ja, zh, th and their kin) all spaces dropped. Digits in the
locale's own script are read as digits. A word CLDR writes with a full stop
is stored with it and without it, and a text with stops is looked up as typed
and then without them, so "wk." and "wk" both read either way; where two words
differ only by the stop (Czech's narrow "m." and "m") the one spelt as typed
wins.

The names of weekdays, months and the parts of a day are read in their wide
and abbreviated widths, and weekdays also in their short one; never in the
narrow width, whose one-letter names are not unique within a locale (English
"T" is Tuesday and Thursday, "S" Saturday, Sunday and September).

Fixed phrases are looked up whole. A counted pattern is a literal before the
number and a literal after it, and both must match the text round its run of
digits exactly; one lookup finds every pattern with those literals. A pattern
CLDR writes with no C<{0}> ("in two days" where
the dual is a word of its own) is a fixed phrase whose count is its plural
category's: C<zero> 0, C<one> 1, C<two> 2. A plural category is never
checked against the number read: "in 1 days" reads 1.

=head1 METHODS

=head2 for

    my $lex = Time::Keeper::Natural::Lexicon->for('fr-CA');

The lexicon of a locale, compiled on first use and shared after; the code is
canonicalised first, so C<fr_ca> and C<fr-CA> share one. An unknown locale dies.

    my $heb = Time::Keeper::Natural::Lexicon->for('en', 'hebrew');

A calendar's id as a second argument gives the lexicon of the locale in that
calendar: its date patterns are the calendar's (L<Time::Keeper::Locale/formats>),
one compiled for each locale and calendar. The Gregorian is the plain
lexicon; an id that is not a calendar dies.

=head2 fixed

The meanings of a text that is a whole phrase, as a list of hash references,
several where phrases normalise alike; empty when it is none. One meaning is
kept for each thing a text can mean: where CLDR writes the same words in
several widths or plural categories, the widest width and the first category
(zero, one, two, few, many, other) are the ones C<width> and C<category> say. A
relative phrase has C<field> (C<year> to C<second>, or C<mon> to C<sun>) and
C<n>, the signed offset; a name has C<weekday> (1 is Monday), C<month> or
C<period> (CLDR's id, C<noon>, C<afternoon1>).

=head2 counted

The meanings of a text that is a counted pattern with its number, "in 3
days": C<field>, C<count> (the number read), C<n> (the count signed by the
direction), C<direction> (1 or -1), C<category> and C<width>. Empty when none
matches.

=head2 read

C<fixed> then C<counted>, in one list.

=head2 unit

The meanings of a duration part, "3 hours", "1 hr", "2 Std.": C<unit> (C<year>
to C<nanosecond>), C<count> and C<n> (the same), C<category>, C<width>.

=head2 bare

    $lex->bare('3 days');       # from "in {0} days" and "{0} days ago", both directions

The meanings of a counted pattern with its direction's marker taken off: the
part of "in 2 weeks and 3 days" that has no "in" of its own. The shape of a
counted meaning, with the C<direction> the pattern came from; the same text
often comes from both directions, and the phrase it sits in decides.

=head2 read_k

=head2 unit_k

=head2 bare_k

As C<read>, C<unit> and C<bare>, for a text already normalised by C<key>:
the grammar's own spans, which it need not normalise twice.

=head2 field_name

    $lex->field_name('month');      # { field => 'month' }

The field a bare unit name is, from CLDR's display names ("month", "mo.",
"months"): what "the end of the month" names.

=head2 markers

    my ($before, $after) = $lex->markers('future');     # ('in ', '') in English

The words a direction adds round a count, found as the longest literal shared
by the direction's eight unit patterns, cut to a whole word: "in" and "ago",
"dans" and "il y a", "後" and "前". Either may be empty.

=head2 joiners

The literals the locale's list patterns put between two items, normalised,
longest first: "and", ", and", "," in English; "et" in French; "و" in Arabic.

=head2 lead_joiners

The joiners CLDR writes with a space before and none after, which a text
carries stuck to the next word: Arabic's "و" ("يومين و3 ساعات"), Hebrew's
"ו-".

=head2 tail_joiners

The joiners written with a space after and none before, stuck to the word
before them: Burmese's "နှင့်".

=head2 number

    $lex->number('21');       # 21

The whole number a text is, or C<undef>: digits in ASCII or the locale's
script, or one of the locale's number words, 0 to 99
(L<Time::Keeper::Natural::Numbers>). A counted pattern reads a number word
where it would read digits: "in two weeks", "dans deux semaines".

=head2 ordinal

The number an ordinal word is, 1 to 31, or C<undef>: "third", "troisième".

=head2 ascii_digits

The text with the locale's digits replaced by ASCII ones.

=head2 normalise

The text as the lexicon stores and looks it up (above).

=head2 key

C<ascii_digits> then C<normalise>: what a text is looked up by.

=head2 code

The locale's canonical code.

=head2 spaceless

True for a locale whose words carry no spaces, where the lexicon drops them all.

=head2 digital

The locale's C<hm>, C<hms> and C<ms> duration patterns, as
L<Time::Keeper::Locale/duration_patterns> gives them.

=head2 lists

    $lex->lists('unit')->{two};     # {0}, {1}

The locale's list pattern of a type, C<standard> by default.

=head2 patterns

    for my $p ($lex->patterns) { $p->{pattern}, $p->{kind}, $p->{year}, $p->{precision} }

The locale's date and time patterns to try a text against, as hash references
in the order to try them: the four datetime formats, then the four date and
four time formats, then every skeleton of C<available_formats>, zone letters
taken out, each also in an unpadded spelling ("H:mm" beside "HH:mm") and a
time pattern also without its spaces ("ha" beside "h a"). C<kind> is
C<datetime>, C<date> or C<time>; C<year> says whether the pattern names one
and C<y_run> how many letters it gives it (2 for a two-digit year);
C<weekday> whether it names a weekday; C<precision> the smallest field; and
C<numeric> how many numbers the text must carry, and C<alpha> whether it must
carry letters (names, a period, a literal word): a text is tried only against
patterns with as many numbers as it has, and with letters when it has them.
C<punct> lists the punctuation the pattern writes outside its quotes, every
one of which the text must carry. Patterns of a quarter, a
week, a day of the year, a bare day or a bare numeric month are left out, so
is a weekday with a time but no date, a time with no hour (minutes and
seconds alone), and a bare hour, which the bare-hour rule reads.

=head2 ties

A hash reference of the normalised phrases that mean more than one thing in
this locale, each to its meanings; French's "du matin" is both the morning and
the night. The grammar resolves them; C<tools/wordcheck> lists them.

=head2 phrases

    my @phrases = $lex->phrases;

The whole phrases the locale's data has, normalised and sorted: relative
words ("tomorrow"), counted phrases with their count spelled in, and the
names of days, months and day periods. C<tools/wordcheck> reads them to show
where a word table's phrase begins one.

=head2 prefixes

    my @prefixes = $lex->prefixes;

The text before the number of each counted pattern, normalised and sorted,
each once ("in ", "", "il y a "): what C<tools/wordcheck> compares to find a
pattern whose words begin another's.

=head1 SEE ALSO

L<Time::Keeper::Natural>, L<Time::Keeper::Locale>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
