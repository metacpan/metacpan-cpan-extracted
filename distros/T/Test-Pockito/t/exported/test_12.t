use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    my $mock   = mock("CarpCall");
    whine(1);

    $SIG{__WARN__} = sub {
            print $_[0];
        ok(
            $_[0] =~
/^Mock call not found to CarpCall->a at t\/.*?.t line \d+$/,
            "Warning properly issued."
        );
    };

    $mock->a;

    package CarpCall;
    use Test::More;

    sub a { }
}
done_testing()
