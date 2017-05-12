use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    my $mock   = mock("Case8");

    when( $mock->hi(1) )->then(2);
    when( $mock->hi )->then(3);

    ok( $mock->hi(1) == 2, "Parameter call worked" );
    ok( $mock->hi == 3,    "Unparametered call worked" );

    package Case8;

    sub hi { }
}
done_testing()
