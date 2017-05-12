#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('URL::Encode::PP', qw[ url_encode
                                  url_encode_utf8
                                  url_decode
                                  url_decode_utf8 ]);
}

sub UNRESERVED () {  "0123456789"
                   . "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                   . "abcdefghijklmnopqrstuvwxyz"
                   . "_.~-" }

my @tests = (
    [ "",         "",     "empty string" ],
    [ "\x{00E5}", "%E5",  "U+00E5 in native encoding" ],
    [ UNRESERVED, UNRESERVED, "unreserved characters" ],
    [ " ", "+", "U+0020 SPACE" ]
);

for my $ord (0x00..0x1F, 0x21..0xFF) {
    my $chr = pack 'C', $ord;
    next unless index(UNRESERVED, $chr) < 0;
    my $enc = sprintf('%%%.2X', $ord);
    push @tests, [ $chr, $enc, sprintf("ordinal %d", $ord) ];
}

foreach my $test (@tests) {
    my ($expected, $encoded, $name) = @$test;
    is(url_decode($encoded), $expected, "url_decode(): $name");
}

foreach my $test (@tests) {
    my ($octets, $expected, $name) = @$test;
    is(url_encode($octets), $expected, "url_encode(): $name");
}

{
    use utf8;
    my $dec = 'blåbär är gött!';
    my $enc = 'bl%E5b%E4r+%E4r+g%F6tt%21';
    is(url_encode($dec), $enc, 'url_encode: native string');
    is(url_decode($enc), $dec, 'url_decode: native string');
}

{
    use utf8;
    my $dec = 'blåbär är gött!';
    my $enc = 'bl%C3%A5b%C3%A4r+%C3%A4r+g%C3%B6tt%21';
    is(url_encode_utf8($dec), $enc, 'url_encode_utf8: UTF-8 string');
    is(url_decode_utf8($enc), $dec, 'url_decode_utf8: UTF-8 string');
}

{
    my $enc = '%AE%Ae%aE';
    my $dec = "\xAE\xAE\xAE";
    is(url_decode($enc), $dec, 'mixed hexadecimal case');
}

done_testing();

