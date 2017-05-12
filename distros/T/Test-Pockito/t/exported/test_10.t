use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    my $mock = mock( "Case14", "b" );

    my $buffer2       = "";
    my $buffer_handle = IO::String->new($buffer2);

    when( $mock->a )->then(1);

    ok( $mock->a == 1, "mock call on partial mock ok" );
    ok( $mock->b == 3, "real call to original method ok" );

    report_expected_calls($buffer_handle);

    ok( $buffer2 eq "",
        "Partial mock left behind no expectations as expectred." );

    package Case14;
    use Test::More;

    sub a { not_ok("Mocked out method should not have been called."); }
    sub b { ok( 1, "Mocked out method call, called as expected" ); 3 }
}
done_testing()
