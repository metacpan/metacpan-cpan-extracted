#!perl

use strict;
use warnings;
use lib 't';

use Test::More tests => 6145;
use Util       qw[throws_ok pack_utf8];

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8
                                encode_utf8 
                                valid_utf8 ]);
}

my @SURROGATES = (0xD800 .. 0xDFFF);

foreach my $cp (@SURROGATES) {
    my $octets = pack_utf8($cp);

    my $name = sprintf 'decode_utf8(<%s>) surrogate U+%.4X',
      join(' ', map { sprintf '%.2X', ord $_ } split //, $octets), $cp;

    throws_ok {
        use warnings FATAL => 'utf8';
        decode_utf8($octets);
    } qr/Can't decode ill-formed UTF-8 octet sequence/, $name;
}

foreach my $cp (@SURROGATES) {
    my $name = sprintf 'encode_utf8("\\x{%.4X}") surrogate U+%.4X',
      $cp, $cp;

    my $string = do { no warnings 'utf8'; pack('U', $cp) };

    throws_ok { 
        use warnings FATAL => 'utf8';
        encode_utf8($string); 
    } qr/Can't represent surrogate code point/, $name;
}

foreach my $cp (@SURROGATES) {
    my $octets = pack_utf8($cp);

    my $name = sprintf 'valid_utf8(<%s>) surrogate U+%.4X',
      join(' ', map { sprintf '%.2X', ord $_ } split //, $octets), $cp;

    ok(!valid_utf8($octets), $name);
}

