use strict;
use warnings;
use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 10;
use Test::Warn;
use Unicode::Util qw( grapheme_split );

is_deeply(
    [ grapheme_split("x\x{44E}\x{44E}\x{301}\x{44E}\x{301}\x{325}") ],  # xю́ю̥́
    [ 'x', "\x{44E}", "\x{44E}\x{301}", "\x{44E}\x{301}\x{325}" ],
    'grapheme_split splits between graphemes'
);

is_deeply(
    [ grapheme_split("\x{44E}\x{301}\x{325}") ],  # ю̥́
    [ "\x{44E}\x{301}\x{325}" ],
    'grapheme_split returns a single grapheme'
);

is_deeply(
    [ grapheme_split('abc') ],
    [ 'a', 'b', 'c' ],
    'grapheme_split splits between single-octet characters'
);

is_deeply(
    [ grapheme_split("abc\n123") ],
    [ 'a', 'b', 'c', "\n", '1', '2', '3' ],
    'grapheme_split handles newline'
);

is_deeply(
    [ grapheme_split("abc\n") ],
    [ 'a', 'b', 'c', "\n" ],
    'grapheme_split handles trailing newline'
);

is_deeply(
    [ grapheme_split('x') ],
    [ 'x' ],
    'grapheme_split returns a single-octet character'
);

is_deeply(
    [ grapheme_split(0) ],
    [ '0' ],
    'grapheme_split returns 0'
);

is_deeply(
    [ grapheme_split('') ],
    [ ],
    'grapheme_split returns empty list for empty string'
);

warning_like {
    is_deeply(
        [ grapheme_split(undef) ],
        [ ],
        'grapheme_split returns empty list for undef'
    );
} (
    qr{^Use of uninitialized value},
    'grapheme_split warns for undef'
);
