use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';

use Test::More;
use Text::UnicodeStyle qw( stylize styles );

my @STYLES = qw(
    bold bold_fraktur bold_italic bold_script
    circled doublestruck fraktur fullwidth italic monospace
    negative_circled negative_squared parenthesized
    sans_serif sans_serif_bold sans_serif_bold_italic sans_serif_italic
    script squared
);

subtest 'styles()' => sub {
    is_deeply [ styles() ], [ sort @STYLES ], 'returns all style names sorted';
};

subtest 'stylize() argument handling' => sub {
    my $s = 'abc';
    stylize($s, 'monospace');
    is $s, 'abc', 'input string is not modified';

    eval { stylize('x', 'no_such_style') };
    like $@, qr/Unknown style/, 'dies on unknown style';
};

my %PUNCT_STYLES = map { $_ => 1 } qw( fullwidth );

subtest 'non-letters are preserved' => sub {
    for my $style (styles()) {
        my $underscore = $PUNCT_STYLES{$style} ? chr(0xFF3F) : '_';
        my $bang       = $PUNCT_STYLES{$style} ? chr(0xFF01) : '!';
        is stylize('a_ Z!', $style),
            stylize('a', $style) . $underscore . ' ' . stylize('Z', $style) . $bang,
            "$style: underscore/space/punctuation handling";
    }
};

subtest 'punctuation (fullwidth only)' => sub {
    is stylize('!@#~', 'fullwidth'),
        join('', map { chr(ord($_) + 0xFEE0) } split //, '!@#~'),
        'fullwidth punctuation uses +0xFEE0 offset';
    is stylize('_', 'fullwidth'), chr(0xFF3F), 'underscore -> fullwidth low line';
    is stylize(' ', 'fullwidth'), ' ', 'space is not fullwidth-mapped';
    for my $style (grep { !$PUNCT_STYLES{$_} } styles()) {
        is stylize('!@#', $style), '!@#', "$style: punctuation unchanged";
    }
};

my %DIGIT_STYLES = map { $_ => 1 } qw(
    bold circled doublestruck fullwidth monospace parenthesized
    sans_serif sans_serif_bold
);

subtest 'digits' => sub {
    for my $style (styles()) {
        my $out = stylize('a1b9', $style);
        if ($DIGIT_STYLES{$style}) {
            unlike $out, qr/[0-9]/, "$style: digits are substituted";
            is length($out), 4, "$style: length preserved";
        }
        else {
            like $out, qr/[0-9]/, "$style: digits are left unchanged";
        }
    }
};

subtest 'digit base code points' => sub {
    is stylize('0', 'bold'),          chr(0x1D7CE), 'bold 0';
    is stylize('9', 'bold'),          chr(0x1D7D7), 'bold 9';
    is stylize('0', 'doublestruck'),  chr(0x1D7D8), 'doublestruck 0';
    is stylize('0', 'sans_serif'),    chr(0x1D7E2), 'sans_serif 0';
    is stylize('0', 'sans_serif_bold'), chr(0x1D7EC), 'sans_serif_bold 0';
    is stylize('0', 'monospace'),     chr(0x1D7F6), 'monospace 0';
    is stylize('9', 'monospace'),     chr(0x1D7FF), 'monospace 9';
    is stylize('0', 'fullwidth'),     chr(0xFF10),  'fullwidth 0';
    is stylize('9', 'fullwidth'),     chr(0xFF19),  'fullwidth 9';
    is stylize('1', 'circled'),       chr(0x2460),  'circled 1';
    is stylize('9', 'circled'),       chr(0x2468),  'circled 9';
    is stylize('0', 'circled'),       chr(0x24EA),  'circled 0 (separate range)';
    is stylize('1', 'parenthesized'), chr(0x2474),  'parenthesized 1';
    is stylize('9', 'parenthesized'), chr(0x247C),  'parenthesized 9';
};

subtest 'parenthesized has no digit zero' => sub {
    is stylize('0', 'parenthesized'), '0',
        'parenthesized 0 stays unchanged (no such glyph)';
    is stylize('109', 'parenthesized'),
        chr(0x2474) . '0' . chr(0x247C),
        'only the zero is left as-is';
};

my %NO_LOWER = map { $_ => 1 } qw(
    negative_circled negative_squared squared
);

subtest 'every style maps the full alphabet to non-ASCII' => sub {
    my $lower = join '', 'a' .. 'z';
    my $upper = join '', 'A' .. 'Z';

    for my $style (styles()) {
        my $out_l = stylize($lower, $style);
        my $out_u = stylize($upper, $style);
        is length($out_u), 26, "$style: uppercase length preserved";
        unlike $out_u, qr/[A-Z]/, "$style: no ASCII uppercase remains";
        is length($out_l), 26, "$style: lowercase length preserved";
        if ($NO_LOWER{$style}) {
            is $out_l, $lower, "$style: no lowercase range, letters unchanged";
        }
        else {
            unlike $out_l, qr/[a-z]/, "$style: no ASCII lowercase remains";
        }
    }
};

subtest 'base code points' => sub {
    is stylize('A', 'monospace'), chr(0x1D670), 'monospace A';
    is stylize('a', 'monospace'), chr(0x1D68A), 'monospace a';
    is stylize('A', 'fullwidth'),  chr(0xFF21),   'fullwidth A';
    is stylize('a', 'fullwidth'),  chr(0xFF41),   'fullwidth a';
    is stylize('A', 'italic'),     chr(0x1D434),  'italic A';
    is stylize('A', 'bold'),       chr(0x1D400),  'bold A';
};

subtest 'enclosed styles base code points' => sub {
    is stylize('A', 'circled'),          chr(0x24B6), 'circled A';
    is stylize('z', 'circled'),          chr(0x24E9), 'circled z';
    is stylize('A', 'parenthesized'),    chr(0x1F110), 'parenthesized A';
    is stylize('z', 'parenthesized'),    chr(0x24B5), 'parenthesized z';
    is stylize('Z', 'squared'),          chr(0x1F149), 'squared Z';
    is stylize('A', 'negative_circled'), chr(0x1F150), 'negative_circled A';
    is stylize('Z', 'negative_squared'), chr(0x1F189), 'negative_squared Z';
};

subtest 'script exceptions' => sub {
    is stylize('BEFHILMR', 'script'),
        "\x{212C}\x{2130}\x{2131}\x{210B}\x{2110}\x{2112}\x{2133}\x{211B}",
        'script uppercase holes use letterlike forms';
    is stylize('ego', 'script'),
        "\x{212F}\x{210A}\x{2134}",
        'script lowercase holes use letterlike forms';
    is stylize('ACXZ', 'script'),
        "\x{1D49C}\x{1D49E}\x{1D4B3}\x{1D4B5}",
        'script contiguous-range letters';
};

subtest 'italic exception' => sub {
    is stylize('h', 'italic'), chr(0x210E), 'italic h -> U+210E';
    is stylize('xyz', 'italic'),
        join('', map { chr(0x1D44E + ord($_) - ord('a')) } split //, 'xyz'),
        'italic contiguous lowercase';
};

subtest 'fraktur exceptions' => sub {
    is stylize('CHIRZ', 'fraktur'),
        "\x{212D}\x{210C}\x{2111}\x{211C}\x{2128}",
        'fraktur uppercase holes use letterlike forms';
};

subtest 'doublestruck exceptions' => sub {
    is stylize('CHNPQRZ', 'doublestruck'),
        "\x{2102}\x{210D}\x{2115}\x{2119}\x{211A}\x{211D}\x{2124}",
        'doublestruck uppercase holes use letterlike forms';
};

done_testing;
