#! perl
use v5.14;
use warnings;

my $in = shift || die "Need float to convert\n";
say unpack( "l", pack( "f", $in ) );
