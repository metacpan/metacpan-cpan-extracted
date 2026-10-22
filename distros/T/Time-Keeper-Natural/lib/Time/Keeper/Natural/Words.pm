package Time::Keeper::Natural::Words;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.07';

use Time::Keeper::Locale;
use Time::Keeper::Natural ();
use Time::Keeper::Natural::Lexicon;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Natural::Words - the words CLDR has none for, one small table a locale

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    my $w = Time::Keeper::Natural::Words->for('en-GB');    # en's table, or undef
    $w->starts('end of last month', 'end_of');             # 'end of'
    $w->phrases('start_of');                               # start of, the start of, ...
    Time::Keeper::Natural::Words->locales;                 # the codes with a table

=head1 DESCRIPTION

CLDR has no words for "start of", "end of", "at", "on" or "the". Those come
from a file a locale, C<words/E<lt>codeE<gt>.txt> beside the module, one key
a line, the key, a tab, and the phrases separated by C<|>.

A phrase stands before what it applies to ("end of", "fin de", "Ende"),
followed by a space, or by nothing when it ends in an apostrophe ("fin d'",
"dell'"); or it is a frame with C<{0}> where the rest goes, as CLDR writes its
own patterns, for a language that puts the word after or round it ("{0}末",
"{0} 말", "{0} का अंत", "{0}ের শেষ"). In a locale whose words carry no spaces,
neither does the match. A locale with no
file of its own reads its parent's (C<en-GB> reads C<en.txt>), and one with
none in its chain has no table: L<Time::Keeper::Natural/coverage> says
C<data> for it. The keys, the whole list:

    start_of   the start of the period that follows
    end_of     the end of it
    at         joins a time to a day, or stands before a time
    on         stands before a day
    skip       words dropped where a part begins ("the")
    and        a chain joiner, where the locale's list pattern has none
    of         between "the third Friday" and its month
    last       "the last Friday of October"
    range      two points as an interval: "from {0} to {1}", "{0} until {1}"
    after      a duration after a point, "{0} after {1}"; or a point alone a day
               on, "the day after {0}"
    before     the same, before it
    weekend    the noun, put where CLDR's "this week" has its word for week
    nth        an ordinal weekday in the language's order, with {period}, {n}
               and {weekday}: "{period}の第{n}{weekday}"
    alias      an inflected form and the CLDR phrase it reads as:
               "nächsten Monats=nächsten Monat"

A key alone means the language needs no word for it. A phrase is matched after
the locale's CLDR words and may not be one: a table that takes one dies when
it loads, naming the phrase and the word. A line C<# test: text =E<gt> value>
is run by C<tools/wordcheck>; a value of two moments with C< / > between
them is an interval, read by L<Time::Keeper::Natural/parse_interval>. A
C<range> phrase holds C<{0}> and then C<{1}>, and none of its three parts may
be a CLDR word.

An C<alias> is the other way round: its phrase must be one of the locale's
CLDR words, and its inflected form must not be. A locale that reads another's
file (C<hi-Latn> reads C<hi.txt>) leaves out an alias whose phrase it lacks.
An C<nth> phrase names each of its three parts once, and its other words may
not be CLDR's. A phrase of C<at>, C<on>, C<of>, C<start_of> or C<end_of> that
ends in C<!> is marked: it may be a CLDR word (German's "am", CLDR's AM), and
it frames only a text that has something after it. C<phrases> gives it with
its mark, and C<tools/wordcheck> lists the marked ones.

=head1 METHODS

=head2 for

The table for a locale, from the nearest file in its chain, or C<undef>.
Read once a locale.

=head2 from_file

    Time::Keeper::Natural::Words->from_file($file, 'en', 'en-GB');

A table read from a file, as C<for> reads one: the file, the code it is for,
and the code whose CLDR words it is checked against (the first by default).

=head2 frame

    my ($rest, $phrase) = $w->frame('fin du mois dernier', 'end_of');   # ('mois dernier', 'fin du')

The text inside the first of a key's phrases that frames it, the longest
phrase first, as typed, and the phrase as the file spells it; an empty list
when none does. Case is ignored and a typographic apostrophe matches a plain one.

=head2 starts

The phrase of C<frame>, or C<undef>.

=head2 split_on

    my ($left, $right, $phrase) = $w->split_on('le troisième vendredi du mois prochain', 'of');

The text either side of the first of a key's phrases standing between two
parts, or an empty list.

=head2 articled

    $w->articled('mois dernier');     # 'mois dernier', 'le mois dernier', 'la mois dernier', ...

The text, then the text after each C<skip> phrase: an article a contraction
swallowed ("fin du mois dernier" is "fin de le mois dernier") put back, for
a locale whose CLDR words carry their article.

=head2 is

True when the text is exactly a phrase of the key.

=head2 phrases

The phrases of a key as the file spells them.

=head2 keys

The keys the file names, including the empty ones.

=head2 tests

The C<# test:> lines, each a text and the value expected.

=head2 code

The code of the file read, C<en> for a parser in C<en-GB>.

=head2 file

Its path.

=head2 locales

The codes that have a file.

=head2 chain

    Time::Keeper::Natural::Words->chain('zh-Hant-HK');    # zh-Hant-HK, zh-Hant, zh

The codes tried for a locale, its own first.

=head2 dir

Where the files are: beside the module once installed, or the distribution's
C<share/words> when the module runs from its own tree.

=head1 SEE ALSO

L<Time::Keeper::Natural>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
