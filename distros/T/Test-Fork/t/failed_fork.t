#!/usr/bin/perl -w

use Test::Builder::Tester tests => 2;
use Test::More;


# Doesn't actually matter what we set errno to, so long as we know
# what the resulting string will be.
my $errno = 1;
my $errno_string;
{
    local $! = $errno;
    $errno_string = $!;
}


# This must come before we use Test::Fork.
BEGIN {
    *CORE::GLOBAL::fork = sub () {
        $! = $errno;
        return undef;
    };
}

use Test::Fork;

is fork(), undef, 'fork deliberately broken';

test_out("not ok 1 - fork() failed: $errno_string");
test_fail(+3);
fork_ok(1, sub {
    fail();
});
test_test("fork_ok() fails when fork() doesn't work");
