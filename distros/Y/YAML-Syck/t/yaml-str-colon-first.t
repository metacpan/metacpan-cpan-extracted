use strict;
use Test::More tests => 129;
use YAML::Syck;

$YAML::Syck::ImplicitUnicode = 1;

for ( my $i = 0; $i <= 2**12; $i += 32 ) {
    my $str  = ":" . chr($i);
    my $dump = Dump( { foo => $str } );
    my $load = Load $dump;
    is( $load->{foo}, $str, "our string #$i starting with a : survived the round-trip" );
}

