#!perl

use strict;
use warnings;

use Test::More tests => 15;

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8 encode_utf8 ]);
}

{
    my @positions;
    my $octets = "\x80 \xE2\x98\xBA \xF4\x80\x80 \xE0\x80\x80";
    my @exp    = ("\x80", "\xF4\x80\x80", "\xE0", "\x80", "\x80");
    my $count  = 0;

    my $fallback = sub {
        my ($octets, $is_usv, $position) = @_;

        my $exp  = shift @exp;
        my $name = sprintf '$sequence eq <%s>',
          join(' ', map { sprintf '%.4X', ord } split //, $exp);

        is($octets, $exp, $name);
        $count++;
        push @positions, $position;
    };

    {
        no warnings 'utf8';
        decode_utf8($octets, $fallback);
    }

    is($count, 5, "decode fallback invoked 5 times");
    is("@positions", "0 6 10 11 12", "got correct octet positions");
}

{
    my @tests = (
        [ "\x80 Foo \xE2\x98\xBA \xE0\x80\x80",
          "\x{FFFD} Foo \x{263A} \x{FFFD}\x{FFFD}\x{FFFD}",
          sub { return "\x{FFFD}" },
        ],
        [ "\x80 Foo \xE2\x98\xBA \xE0\x80\x80",
          "\x80 Foo \x{263A} \xE0\x80\x80",
          sub { return $_[0] }
        ],
        [ "\xEF\xB7\x90 Foo \xEF\xB7\xA0 \xE0\x80\x80",
          "! Foo ! \x{FFFD}\x{FFFD}\x{FFFD}",
          sub { return $_[1] ? '!' : "\x{FFFD}" }
        ],
    );

    foreach my $test (@tests) {
        my ($octets, $exp, $fallback) = @$test;

        my $name = sprintf 'decode_utf8(<%s>) eq <%s>',
          join(' ', map { sprintf '%.2X', ord } split //, $octets),
          join(' ', map { sprintf '%.4X', ord } split //, $exp);

        my $got = do {
            no warnings 'utf8';
            decode_utf8($octets, $fallback);
        };

        is($got, $exp, $name);
    }
}

{
    my @tests = (
        [ "\x{110000}",
          0x110000,
          sub { return $_[0] },
        ],
        [ "\x{110000} Foo \x{263A} \x{110000}",
          "\xEF\xBF\xBD Foo \xE2\x98\xBA \xEF\xBF\xBD",
          sub { return "\x{FFFD}" },
        ],
        [ "\x{110000} Foo \x{263A} \x{110000}",
          " Foo \xE2\x98\xBA ",
          sub { return '' }
        ],
        [ "\x{FDD0} Foo \x{263A} \x{FDE0}",
          "! Foo \xE2\x98\xBA !",
          sub { return $_[1] ? '!' : "\x{FFFD}" }
        ],
    );

    foreach my $test (@tests) {
        my ($string, $exp, $fallback) = @$test;

        my $name = sprintf 'encode_utf8(<%s>) eq <%s>',
          join(' ', map { sprintf '%.2X', ord } split //, $string),
          join(' ', map { sprintf '%.4X', ord } split //, $exp);

        my $got = do {
            no warnings 'utf8';
            encode_utf8($string, $fallback);
        };

        is($got, $exp, $name);
    }
}

