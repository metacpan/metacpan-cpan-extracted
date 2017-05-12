#!perl

use strict;
use warnings;
use lib 't';

use Test::More;
use Test::Fatal qw[lives_ok];
use Util        qw[throws_ok warns_ok];

BEGIN {
    plan skip_all => 'Perl 5.14 required for this test' if $] < 5.014;
    plan tests => 6;
}

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8 encode_utf8 ]);
}

{
    use warnings FATAL => 'utf8';
    no warnings 'nonchar';
    lives_ok { 
        decode_utf8("\xEF\xBF\xBF");
    } 'decode_utf8() FATAL => utf8, no warnings nonchar';
}

{
    use warnings FATAL => 'utf8';
    no warnings 'nonchar';
    lives_ok { 
        encode_utf8("\x{FFFF}");
    } 'encode_utf8() FATAL => utf8, no warnings nonchar';
}

{
    use warnings FATAL => 'utf8', NONFATAL => 'nonchar';
    warns_ok {
        decode_utf8("\xEF\xBF\xBF");
    } qr/Can't interchange noncharacter code point/, 'decode_utf8() FATAL => utf8, NONFATAL => nonchar';
}

{
    no warnings 'utf8';
    use warnings FATAL => 'nonchar';
    throws_ok { 
        decode_utf8("\xEF\xBF\xBF");
    } qr/Can't interchange noncharacter code point/, 'decode_utf8() FATAL => nonchar, no warnings utf8';
}

{
    no warnings 'utf8';
    use warnings FATAL => 'nonchar';
    throws_ok { 
        encode_utf8("\x{FFFF}");
    } qr/Can't interchange noncharacter code point/, 'encode_utf8() FATAL => nonchar, no warnings utf8';
}

