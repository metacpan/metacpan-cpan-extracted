use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    my $mock   = mock("Case7");

    when( $mock->hello("are you there?") )->then(1);

    my ($foo) = $mock->hello("are you there?");

    ok( $foo == 1, "AUTOLOAD works" );

    package Case7;

    sub AUTOLOAD { }

}
done_testing()
