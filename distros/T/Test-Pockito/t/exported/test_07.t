use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    setup("_Pockito", \&Case10Matcher );
 
    my $mock = mock("Case10");

    when( $mock->rawr(2) )->default(3);

    ok( ( $mock->rawr(1) == 3 ), "Matcher performed as expected" );

    sub Case10Matcher {
        my $package        = shift;
        my $method         = shift;
        my $param_found    = shift;
        my $param_expected = shift;
        my $result         = shift;

        ok( "_Pockito::Case10" eq $package, "Package name passed as expected." );
        ok( "rawr"        eq $method,  "Method name passed as expected." );
        ok( $$param_expected[0] == 2, "Expected param passed properly" );

        return 1, 3 if $$param_found[0] == 1;
    }

    package Case10;

    sub rawr { }
}
done_testing()
