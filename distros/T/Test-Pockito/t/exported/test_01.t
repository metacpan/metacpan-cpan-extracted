use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    my $mock   = mock("Case1");

    when( $mock->hello("are you there?") )->then("hi!");
    when( $mock->hello("are you there?") )->then("hello!");

    ok( $mock->hello("are you there?") eq "hi!", "First in 2 calls correct" );
    ok( $mock->hello("are you there?") eq "hello!", "Last in 2 calls correct" );

    package Case1;

    sub hello { }
}
done_testing()
