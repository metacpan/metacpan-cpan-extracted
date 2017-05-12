#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
    eval 'use Variable::Magic qw[cast wizard];';
    plan skip_all => 'Variable::Magic is required for this test' if $@;
    plan tests => 13;
}

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8
                                encode_utf8 ]);
}

my ($string_get,
    $string_set,
    $octets_get,
    $octets_set);

my $w_string = wizard get => sub { $string_get++ },
                      set => sub { $string_set++ };

my $w_octets = wizard get => sub { $octets_get++ },
                      set => sub { $octets_set++ };


($string_get, $string_set, $octets_get, $octets_set) = (0, 0, 0, 0);

{
    my $octets = "\x80\x80\x80";
    my $string;

    cast $octets, $w_octets;
    cast $string, $w_string;
    {
        no warnings 'utf8';
        $string = decode_utf8($octets);
    }

    is($octets_get, 1, 'decode_utf8() $octets GET magic');
    is($octets_set, 0, 'decode_utf8() $octets SET magic');
    is($string_get, 0, 'decode_utf8() $string GET magic');
    is($string_set, 1, 'decode_utf8() $string SET magic');
}

($string_get, $string_set, $octets_get, $octets_set) = (0, 0, 0, 0);

{
    my $octets = "Foo \xE2\x98\xBA";
    my $string;

    utf8::upgrade($octets);

    cast $octets, $w_octets;
    cast $string, $w_string;
    {
        no warnings 'utf8';
        $string = decode_utf8($octets);
    }

    is($octets_get, 1, 'decode_utf8(upgraded) $octets GET magic');
    is($octets_set, 0, 'decode_utf8(upgraded) $octets SET magic');
    is($string_get, 0, 'decode_utf8(upgraded) $string GET magic');
    is($string_set, 1, 'decode_utf8(upgraded) $string SET magic');
}

($string_get, $string_set, $octets_get, $octets_set) = (0, 0, 0, 0);

{
    my $string = "\x{110000}\x{110000}\x{110000}";
    my $octets;

    cast $octets, $w_octets;
    cast $string, $w_string;
    {
        no warnings 'utf8';
        $octets = encode_utf8($string);
    }

    is($octets_get, 0, 'encode_utf8() $octets GET magic');
    is($octets_set, 1, 'encode_utf8() $octets SET magic');
    is($string_get, 1, 'encode_utf8() $string GET magic');
    is($string_set, 0, 'encode_utf8() $string SET magic');
}


