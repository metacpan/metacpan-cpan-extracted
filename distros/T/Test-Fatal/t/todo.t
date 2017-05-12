#!/usr/bin/perl

use strict;

use Test::Builder::Tester tests => 4;

use Test::More;
use Test::Fatal;

my $file = __FILE__;

{
    my $line = __LINE__ + 13;
    my $out = <<FAIL;
not ok 1 - succeeded # TODO unimplemented
#   Failed (TODO) test 'succeeded'
#   at $file line $line.
#          got: '0'
#     expected: '1'
ok 2 - no exceptions # TODO unimplemented
FAIL
    chomp($out);
    test_out($out);
    {
        local $TODO = "unimplemented";
        is(exception { is(0, 1, "succeeded") }, undef, "no exceptions");
    }
    test_test( "\$TODO works" );
}

{
    my $line = __LINE__ + 13;
    my $out = <<FAIL;
not ok 1 - succeeded # TODO unimplemented
#   Failed (TODO) test 'succeeded'
#   at $file line $line.
#          got: '0'
#     expected: '1'
ok 2 - no exceptions # TODO unimplemented
FAIL
    chomp($out);
    test_out($out);
    {
        local $TODO = "unimplemented";
        stuff_is_ok(0, 1);
    }
    test_test( "\$TODO works" );

    sub stuff_is_ok {
        my ($got, $expected) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        is(
            exception { is($got, $expected, "succeeded") },
            undef,
            "no exceptions"
        );
    }
}

{
    my $line = __LINE__ + 13;
    my $out = <<FAIL;
not ok 1 - succeeded # TODO unimplemented
#   Failed (TODO) test 'succeeded'
#   at $file line $line.
#          got: '0'
#     expected: '1'
ok 2 - no exceptions # TODO unimplemented
FAIL
    chomp($out);
    test_out($out);
    {
        local $TODO = "unimplemented";
        stuff_is_ok2(0, 1);
    }
    test_test( "\$TODO works" );

    sub stuff_is_ok2 {
        my ($got, $expected) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        _stuff_is_ok2(@_);
    }

    sub _stuff_is_ok2 {
        my ($got, $expected) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        is(
            exception { is($got, $expected, "succeeded") },
            undef,
            "no exceptions"
        );
    }
}

{
    my $line = __LINE__ + 14;
    my $out = <<FAIL;
not ok 1 - succeeded # TODO unimplemented
#   Failed (TODO) test 'succeeded'
#   at $file line $line.
#          got: '0'
#     expected: '1'
ok 2 - no exceptions # TODO unimplemented
ok 3 - level 1 # TODO unimplemented
FAIL
    chomp($out);
    test_out($out);
    {
        local $TODO = "unimplemented";
        multi_level_ok(0, 1);
    }
    test_test( "\$TODO works" );

    sub multi_level_ok {
        my ($got, $expected) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        is(
            exception { _multi_level_ok($got, $expected) },
            undef,
            "level 1"
        );
    }

    sub _multi_level_ok {
        my ($got, $expected) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        is(
            exception { is($got, $expected, "succeeded") },
            undef,
            "no exceptions"
        );
    }
}
