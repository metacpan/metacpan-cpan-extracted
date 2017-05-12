package Try::Tiny::WarnCaughtTest;
use strictures;
use true;
use Test::Most;

use Try::Tiny;
use Try::Tiny::WarnCaught;

my $should_warn = sub {
    try {
        die "hello world";
    } catch {
        1;
    }
};

warning_is { $should_warn->() } "Caught exception: hello world",
    "catch block warns automatically now"
;

done_testing;
