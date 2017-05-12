use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    my $mock   = mock("Edge1");

    when( $mock->a() )->default(1);
    when( $mock->a(2) )->default(2);

    ok( $mock->a == 1,    "Initial default works." );
    ok( $mock->a(2) == 2, "Initial default with a param works." );

    when( $mock->a() )->default(2.1);

    ok( $mock->a(2) == 2, "Default with param continues to work" );
    ok( $mock->a == 2.1,  "new default works." );
    ok( $mock->a == 2.1,  "new default really works" );

    package Edge1;

    sub a { }
}
done_testing()
