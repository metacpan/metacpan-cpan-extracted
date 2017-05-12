use strict;
use warnings;
use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 21;
use Test::Warn;
use Unicode::Util qw( grapheme_reverse );

my $str = "ю\x{0301}xя\x{0305}\x{0308}\x{0321}";  # ю́xя̡̅̈

is(
    scalar grapheme_reverse($str),
    "я\x{0305}\x{0308}\x{0321}xю\x{0301}",  # я̡̅̈xю́
    'grapheme_reverse on string of grapheme clusters in scalar context'
);

is_deeply(
    [grapheme_reverse($str)],
    [$str],
    'grapheme_reverse on string of grapheme clusters in list context'
);

is(
    scalar grapheme_reverse('a', ($str) x 2, 'z'),
    'z' . "я\x{0305}\x{0308}\x{0321}xю\x{0301}" x 2 . 'a',  # zя̡̅̈xю́я̡̅̈xю́a
    'grapheme_reverse on list of strings of grapheme clusters in scalar context'
);

is_deeply(
    [grapheme_reverse('a', ($str) x 2, 'z')],
    ['z', ($str) x 2, 'a'],
    'grapheme_reverse on list of strings of grapheme clusters in list context'
);

warning_like {
    is(
        scalar grapheme_reverse(undef),
        '',
        'grapheme_reverse on undef in scalar context'
    );
} qr{^Use of uninitialized value}, 'warns on undef';

is_deeply(
    [grapheme_reverse(undef)],
    [undef],
    'grapheme_reverse on undef in list context'
);

warnings_like {
    is(
        scalar grapheme_reverse(undef, undef),
        '',
        'grapheme_reverse on list of undef in scalar context'
    );
} [(qr{^Use of uninitialized value}) x 2], 'warns for each undef';

is_deeply(
    [grapheme_reverse(undef, undef)],
    [undef, undef],
    'grapheme_reverse on list of undef in list context'
);

$_ = $str;

is(
    scalar grapheme_reverse(),
    "я\x{0305}\x{0308}\x{0321}xю\x{0301}",  # я̡̅̈xю́
    'grapheme_reverse on string of grapheme clusters in scalar context using $_'
);

is_deeply(
    [grapheme_reverse()],
    [],
    'grapheme_reverse with no arguments in list context'
);

warning_like {
    is(
        scalar grapheme_reverse(undef),
        '',
        'grapheme_reverse on undef in scalar context when $_ is set'
    );
} qr{^Use of uninitialized value}, 'warns on undef';

is_deeply(
    [grapheme_reverse(undef)],
    [undef],
    'grapheme_reverse on undef in list context whe $_ is set'
);

undef $_;

warning_like {
    is(
        scalar grapheme_reverse(),
        '',
        'grapheme_reverse on undef in scalar context using $_'
    );
} qr{^Use of uninitialized value}, 'warns on undef';

# tests adapted from examples in perlfunc/reverse

is_deeply [grapheme_reverse('world', 'Hello')], ['Hello', 'world'];
is scalar grapheme_reverse('dlrow ,', 'olleH'), 'Hello, world';

$_ = 'dlrow ,olleH';
is_deeply [grapheme_reverse()], [], 'No output, list context';
is scalar grapheme_reverse(), 'Hello, world';
