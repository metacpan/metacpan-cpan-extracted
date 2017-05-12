use strict;
use warnings;
use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 16;
use Unicode::Util qw( grapheme_substr );

my $s = 'Hello';
is grapheme_substr($s, 5, 999, 'o'), '';
is $s, 'Helloo';

# tests adapted from examples in perlfunc/substr

$s = 'The black cat climbed the green tree';
is grapheme_substr($s,  4,   5), 'black';
is grapheme_substr($s,  4, -11), 'black cat climbed the';
is grapheme_substr($s, 14),      'climbed the green tree';
is grapheme_substr($s, -4),      'tree';
is grapheme_substr($s, -4, 2),   'tr';

is grapheme_substr($s, 14, 7, 'jumped from'), 'climbed';
is $s, 'The black cat jumped from the green tree';

$s = 'Hello';
is grapheme_substr($s, 0, 999), 'Hello';

# tests adapted from Unicode::GCString (t/10gcstring.t)

SKIP: {
    skip 'requires extended graheme clusters from Perl v5.12', 6 if $] < 5.012;

    $s = "\x{1112}\x{1161}\x{11AB}\x{1100}\x{1173}\x{11AF}";

    is grapheme_substr($s,  1),     "\x{1100}\x{1173}\x{11AF}";
    is grapheme_substr($s, -1),     "\x{1100}\x{1173}\x{11AF}";
    is grapheme_substr($s,  0, -1), "\x{1112}\x{1161}\x{11AB}";

    grapheme_substr($s, -1, 1, 'A'); is $s, "\x{1112}\x{1161}\x{11AB}A";
    grapheme_substr($s,  2, 0, 'B'); is $s, "\x{1112}\x{1161}\x{11AB}AB";
    grapheme_substr($s,  0, 0, 'C'); is $s, "C\x{1112}\x{1161}\x{11AB}AB";
}
