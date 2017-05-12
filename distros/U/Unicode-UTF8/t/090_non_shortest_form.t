#!perl

use strict;
use warnings;
use lib 't';

use Test::More tests => 46;
use Encode     qw[_utf8_on];
use Util       qw[throws_ok pack_overlong_utf8];

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8
                                encode_utf8 
                                valid_utf8 ]);
}

my @tests = (
      0x00,
      0x80,
     0x800,
    0x1000,
);

foreach my $cp (@tests) {
    foreach my $sequence (pack_overlong_utf8($cp)) {
        my $name = sprintf 'decode_utf8(<%s>) non-shortest form representation of U+%.4X',
          join(' ', map { sprintf '%.2X', ord $_ } split //, $sequence), $cp;

        throws_ok {
            use warnings FATAL => 'utf8';
            decode_utf8($sequence);
        } qr/Can't decode ill-formed UTF-8 octet sequence/, $name;
    }
}

foreach my $cp (@tests) {
    foreach my $sequence (pack_overlong_utf8($cp)) {
        my $name = sprintf 'encode_utf8(<%s>) non-shortest form representation of U+%.4X',
          join(' ', map { sprintf '%.2X', ord $_ } split //, $sequence), $cp;

        _utf8_on($sequence);
        throws_ok { 
            encode_utf8($sequence);
        } qr/Can't decode ill-formed UTF-X octet sequence/, $name;
    }
}

foreach my $cp (@tests) {
    foreach my $sequence (pack_overlong_utf8($cp)) {
        my $name = sprintf 'valid_utf8(<%s>) non-shortest form representation of U+%.4X',
          join(' ', map { sprintf '%.2X', ord $_ } split //, $sequence), $cp;

        ok(!valid_utf8($sequence), $name);
    }
}

