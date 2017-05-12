#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;

use Test::Run::Obj;
use Test::Run::Plugin::BreakOnFailure;

use Test::Run::Trap::Obj;

package MyTestRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Plugin::BreakOnFailure Test::Run::Obj));

package main;

use Test::More tests => 2;

{
    my $got = Test::Run::Trap::Obj->trap_run(
        {
            class => "MyTestRun",
            args =>
            [
                test_files =>
                [
                    "t/sample-tests/one-fail.t",
                    "t/sample-tests/one-ok.t",
                ],
                should_break_on_failure => 1,
            ],
        }
        );

    # TEST
    $got->field_unlike("stdout", qr/one-ok/,
        "Successful tests were skipped upon failure."
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run(
        {
            class => "MyTestRun",
            args =>
            [
                test_files =>
                [
                    "t/sample-tests/one-fail.t",
                    "t/sample-tests/one-ok.t",
                ],
                should_break_on_failure => '',
            ],
        }
        );

    # TEST
    $got->field_like("stdout", qr/one-ok/,
        "Failing test did not break the run of the rest upon no should_break_on_failure."
    );
}
