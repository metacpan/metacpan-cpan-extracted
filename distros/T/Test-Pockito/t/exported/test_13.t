use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    my $mock   = mock("Case2");

    ok( $mock->can("hello"),   "Propper method discovery" );
    ok( !$mock->can("hello1"), "Propper method discovery (missing method)" );
    ok( $mock->isa('Case2'),   "Proper subclassing" );

    package Case2;

    sub hello { }
}
{
    setup("Foo");
    my $mock   = mock("Case3");

    ok( ref $mock eq "Foo::Case3", "Create a mock with a namespace" );

    package Foo;
}
{
    my $mock   = mock("Case4");

    when( $mock->hello("are you there?") )->then("hi!");

    ok( $mock->hello("are you there?") eq "hi!", "Mock returned scalar" );

    package Case4;

    sub hello { }
}
done_testing()
