#!perl

use strict;
use warnings;
use lib 't';

use Test::More tests => 463;
use Util       qw[throws_ok warns_ok pack_utf8];

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8
                                encode_utf8 
                                valid_utf8 ]);
}

my @NONCHARACTERS = (0xFDD0 .. 0xFDEF);
{
    for (my $i = 0; $i < 0x10FFFF; $i += 0x10000) {
        push @NONCHARACTERS, $i ^ 0xFFFE, $i ^ 0xFFFF;
    }
}

foreach my $cp (@NONCHARACTERS) {
    my $octets = pack_utf8($cp);

    my $name = sprintf 'decode_utf8(<%s>) noncharacter U+%.4X',
      join(' ', map { sprintf '%.2X', ord $_ } split //, $octets), $cp;

    my $match = qr/Can't interchange noncharacter code point/;

    throws_ok {
        use warnings FATAL => 'utf8';
        decode_utf8($octets);
    } $match, "$name throws an exception";

    my $got;

    warns_ok {
        use warnings 'utf8';
        $got = decode_utf8($octets);
    } $match, "$name issues a warning";

    is($got, "\x{FFFD}", "$name returned U+FFFD");
}

foreach my $cp (@NONCHARACTERS) {
    my $name = sprintf 'encode_utf8("\\x{%.4X}") noncharacter U+%.4X',
      $cp, $cp;

    my $string = do { no warnings 'utf8'; pack('U', $cp) };
    my $match  = qr/Can't interchange noncharacter code point/;
    my $exp    = do { utf8::encode(my $s = "\x{FFFD}"); $s };

    throws_ok {
        use warnings FATAL => 'utf8';
        encode_utf8($string)
    } $match, "$name throws an exception";

    my $got;

    warns_ok {
        use warnings 'utf8';
        $got = encode_utf8($string)
    } $match, "$name issues a warning";

    is($got, $exp, "$name returned encoded U+FFFD");
}

foreach my $cp (@NONCHARACTERS) {
    my $octets = pack_utf8($cp);

    my $name = sprintf 'valid_utf8(<%s>) noncharacter U+%.4X',
      join(' ', map { sprintf '%.2X', ord $_ } split //, $octets), $cp;

    ok(!valid_utf8($octets), $name);
}

