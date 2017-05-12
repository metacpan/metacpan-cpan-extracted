use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    setup("Foo");
    my $mock   = mock("Case11");

    when( $mock->hi( 'hello',   'bonjour' ) )->then(3);
    when( $mock->hi( 'go away', 'beat it' ) )->then(2);

    my $missing_calls = expected_calls();

    ok( $missing_calls->{'Foo::Case11'}{'hi'}[0]->{'params'}->[0] eq 'hello',
        "call 1, param 1 report matches" );
    ok( $missing_calls->{'Foo::Case11'}{'hi'}[0]->{'params'}->[1] eq 'bonjour',
        "call 1, param 2 report matches" );
    ok( $missing_calls->{'Foo::Case11'}{'hi'}[0]->{'result'}->[0] == 3,
        "call 1, expected result matches" );

    ok( $missing_calls->{'Foo::Case11'}{'hi'}[1]->{'params'}->[0] eq 'go away',
        "call 2, param 1 report matches" );
    ok( $missing_calls->{'Foo::Case11'}{'hi'}[1]->{'params'}->[1] eq 'beat it',
        "call 2, param 2 report matches" );
    ok( $missing_calls->{'Foo::Case11'}{'hi'}[1]->{'result'}->[0] == 2,
        "call 2, expected result matches" );

    ok( $mock->hi( 'hello', 'bonjour' ) == 3, "other call after report works" );
    ok( $mock->hi( 'go away', 'beat it' ) == 2,
        "mock call after report works" );

    ok( scalar keys %{ expected_calls() } == 0,
        "Mock removed expectation" );

    package Case11;

    sub hi { }
}
done_testing()
