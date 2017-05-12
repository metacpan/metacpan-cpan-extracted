#!perl

use strict;
use warnings;
use lib 't';

use Test::More  tests => 7;
use Test::Fatal qw[lives_ok];
use Util        qw[throws_ok];

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8
                                valid_utf8 ]);
}

{
    my $got;
    utf8::decode(my $exp = "blåbär är gött!");
    utf8::upgrade(my $octets = "blåbär är gött!");
    lives_ok { $got = decode_utf8($octets); } 'decode_utf8() upgraded UTF-8 octets';
    is($got, $exp, "Got expected string");
}

{
    my $got;
    utf8::upgrade(my $octets = "blåbär är gött!");
    lives_ok { $got = valid_utf8($octets); } 'valid_utf8() upgraded UTF-8 octets';
    ok($got, 'Got expected result');
}

{
    use utf8;
    my $str = "\x{26C7}";
    throws_ok { decode_utf8($str); } qr/Can't decode a wide character string/, 'wide character string';
}

{
    use utf8;
    my $str = "\x{26C7}";
    throws_ok { valid_utf8($str); } qr/Can't validate a wide character string/, 'wide character string';
}

