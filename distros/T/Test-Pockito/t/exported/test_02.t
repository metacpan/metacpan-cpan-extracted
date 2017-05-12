use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    my $mock   = mock("Case5");

    when( $mock->hello("are you there?") )->then( "hi!", "hello!" );

    my ( $a, $b ) = $mock->hello("are you there?");

    ok( $a eq "hi!",    "Mock returned first part of array correctly" );
    ok( $b eq "hello!", "Mock returned second part of array correctly" );

    package Case5;

    sub hello { }
}
done_testing()
