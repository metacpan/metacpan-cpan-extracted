use strict;

use Test::More;
if ( eval { require Encode } ) {
    plan tests => 2;
} else {
    plan skip_all => "No Encode module, old perl";
}

use_ok('Text::Quoted');

$a = Encode::decode_utf8("x\303\203 \tz");
is_deeply( extract($a), [ { 
    text   => Encode::decode_utf8("x\303\203      z"),
    quoter => '',
    raw    => Encode::decode_utf8("x\303\203      z"),
} ], "No segfault");
