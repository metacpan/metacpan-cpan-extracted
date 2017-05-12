use strict;
use warnings;
use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 11;
use Test::Warn;
use Unicode::Util qw( grapheme_length );

is grapheme_length("\x{44E}\x{301}"), 1, 'graphemes in grapheme cluster';
is grapheme_length('abc'),            3, 'graphemes in ASCII string';

warning_like {
    is grapheme_length(undef), 0, '0 when called on undef';
} qr{^Use of uninitialized value}, 'warns on undef';

$_ = "\x{44E}\x{301}";
is grapheme_length(),      1, 'graphemes in grapheme cluster using $_';

warning_like {
    is grapheme_length(undef), 0, 'still 0 when called on undef when $_ is set';
} qr{^Use of uninitialized value}, 'warns on undef';

undef $_;

warning_like {
    is grapheme_length(), 0, '0 when called on undef using $_';
} qr{^Use of uninitialized value}, 'warns on undef';

# tests adapted from Unicode::GCString (t/10gcstring.t)

SKIP: {
    skip 'requires extended graheme clusters from Perl v5.12', 2 if $] < 5.012;

    is grapheme_length("\x{300}\x{0}\x{D}A\x{300}\x{301}\x{3042}\x{D}\x{A}\x{AC00}\x{11A8}"), 7;
    is grapheme_length("\x{1112}\x{1161}\x{11AB}\x{1100}\x{1173}\x{11AF}"), 2;
}
