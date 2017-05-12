use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    my $mock   = mock("Case6");

    when( $mock->hello("are you there?") )->then();

    my ($foo) = $mock->hello("are you there?");

    ok( !defined $foo, "Mock method in null context" );

    package Case6;

    sub hello { }
}
done_testing()
