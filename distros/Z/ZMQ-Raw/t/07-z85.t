#!perl

use Test::More;
use ZMQ::Raw;

my $decoded = "abcd";
my $encoded = ZMQ::Raw::Z85->encode ($decoded);
is length ($encoded), 5;
is length (ZMQ::Raw::Z85->decode ($encoded)), 4;
is $decoded, ZMQ::Raw::Z85->decode ($encoded);

ok (!eval {ZMQ::Raw::Z85->encode ("abcde")});
ok (!eval {ZMQ::Raw::Z85->decode ("abcd")});

done_testing;

