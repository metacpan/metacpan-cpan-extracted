use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    my $mock   = mock("Case7");

    when( $mock->string("are you there?") )->then("string");
    when( $mock->number("are you there?") )->then(9);

    my ($string) = $mock->string("are you there?");
    my ($number) = $mock->number("are you there?");

    ok( $string eq "string", "string comparison works" );
    ok( $number == 9, "number comparison works" );

    package Case7;

    sub string { }
    sub number { }

}
done_testing()
