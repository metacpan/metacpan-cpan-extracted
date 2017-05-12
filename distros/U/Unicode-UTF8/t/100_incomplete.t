#!perl

use strict;
use warnings;
use lib 't';

use Test::More tests => 817;
use Encode     qw[_utf8_on];
use Util       qw[throws_ok pack_utf8];

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8
                                encode_utf8 
                                valid_utf8 ]);
}

my @INCOMPLETE = ();

{
    for (my $i = 0x80; $i < 0x10FFFF; $i += 0x1000) {
        push @INCOMPLETE, substr(pack_utf8($i), 0, -1);
    }
}

foreach my $sequence (@INCOMPLETE) {
    my $name = sprintf 'decode_utf8(<%s>) incomplete UTF-8 sequence',
      join(' ', map { sprintf '%.2X', ord $_ } split //, $sequence);

    throws_ok {
        use warnings FATAL => 'utf8';
        decode_utf8($sequence);
    } qr/Can't decode ill-formed UTF-8 octet sequence/, $name;
}

foreach my $sequence (@INCOMPLETE) {
    my $name = sprintf 'encode_utf8(<%s>) incomplete UTF-8 sequence',
      join(' ', map { sprintf '%.2X', ord $_ } split //, $sequence);

    _utf8_on(my $sequence = $sequence);
    throws_ok {
        encode_utf8($sequence);
    } qr/Can't decode ill-formed UTF-X octet sequence/, $name;
}

foreach my $sequence (@INCOMPLETE) {
    my $name = sprintf 'valid_utf8(<%s>) incomplete UTF-8 sequence',
      join(' ', map { sprintf '%.2X', ord $_ } split //, $sequence);

    ok(!valid_utf8($sequence), $name);
}

