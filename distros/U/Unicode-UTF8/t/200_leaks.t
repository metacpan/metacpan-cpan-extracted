#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
    eval 'use Test::LeakTrace 0.10;';
    plan skip_all => 'Test::LeakTrace 0.10 is required for this test' if $@;
    plan tests => 3;
}

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8
                                encode_utf8 ]);
}

no_leaks_ok {
    my $octets = 'Flygande bäckasiner söka hwila på mjuka tuvor';
    my $string = decode_utf8($octets);
} 'decode_utf8()';

no_leaks_ok {
    my $string = do {
        use utf8;
        'Flygande bäckasiner söka hwila på mjuka tuvor';
    };
    my $octets = encode_utf8($string);
} 'encode_utf8()';

