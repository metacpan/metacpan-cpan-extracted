#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
    eval 'use Taint::Runtime 0.03 qw[taint_start tainted is_tainted];';
    plan skip_all => 'Taint::Runtime 0.03 is required for this test' if $@;
    plan tests => 7;
}

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8
                                encode_utf8 ]);
}

my $octets = 'Flygande bäckasiner söka hwila på mjuka tuvor';

taint_start();

{
    my ($a, $b);

    $a = decode_utf8($octets);
    $b = decode_utf8($octets . tainted());

    ok(!is_tainted($a), '$a = decode_utf8() is not tainted');
    ok(is_tainted($b), '$b = decode_utf8() is tainted');
}

{
    my ($a, $b);

    my $string = do {
        use utf8;
        'Flygande bäckasiner söka hwila på mjuka tuvor';
    };

    $a = encode_utf8($string);
    $b = encode_utf8($string . tainted());

    ok(!is_tainted($a), '$a = encode_utf8() is not tainted');
    ok(is_tainted($b), '$b = encode_utf8() is tainted');
}

{
    my ($a, $b);

    my $string = "Flygande b\xE4ckasiner s\xF6ka hwila p\xE5 mjuka tuvor";

    $a = encode_utf8($string);
    $b = encode_utf8($string . tainted());

    ok(!is_tainted($a), '$a = encode_utf8(native string) is not tainted');
    ok(is_tainted($b), '$b = encode_utf8(native string) is tainted');
}

