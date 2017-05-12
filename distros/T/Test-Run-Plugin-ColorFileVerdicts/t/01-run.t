#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use Test::Run::Trap::Obj;

package MyTestRun;

use base 'Test::Run::Plugin::ColorFileVerdicts';
use base 'Test::Run::Obj';

package main;

use Term::ANSIColor;

{
    my $got = Test::Run::Trap::Obj->trap_run(
        {
            class => "MyTestRun",
            args =>
            [
            test_files =>
            [
                "t/sample-tests/one-ok.t",
                "t/sample-tests/several-oks.t"
            ],
            ]
        }
        );

    my $color = color("green");
    my $reset = color("reset");

    # TEST
    $got->field_like("stdout", qr/\Q${color}\Eok\Q${reset}\E/,
        "ok is colored green");
}

{
    my $got = Test::Run::Trap::Obj->trap_run(
        {
            class => "MyTestRun",
            args =>
            [
            test_files =>
            [
                "t/sample-tests/simple_fail.t",
            ],
            ]
        }
        );

    my $color = color("red");
    my $reset = color("reset");

    # TEST
    $got->field_like("stdout", qr/\Q${color}\EFAILED tests.*?\Q${reset}\E/,
        "not ok is colored red by default");
}

{
    my $got = Test::Run::Trap::Obj->trap_run(
        {
            class => "MyTestRun",
            args =>
            [
            test_files =>
            [
                "t/sample-tests/one-ok.t",
                "t/sample-tests/several-oks.t"
            ],
            individual_test_file_verdict_colors =>
            {
                success => "yellow",
                failure => "blue",
            },
            ],
        }
        );

    my $color = color("yellow");
    my $reset = color("reset");

    # TEST
    $got->field_like("stdout", qr/\Q${color}\Eok\Q${reset}\E/,
        "ok is colored yellow per the explicit setup"
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
                "t/sample-tests/one-ok.t",
                "t/sample-tests/one-fail-exit-0.t"
            ],
            individual_test_file_verdict_colors =>
            {
                success => "yellow",
                failure => "blue",
            },
            ],
        }
        );

    my $color = color("blue");
    my $reset = color("reset");

    # TEST
    $got->field_like ("stdout", qr/\Q${color}\EFAILED test 1\Q${reset}\E/,
        "FAILED test 1 colored.");
}

{
    my $got = Test::Run::Trap::Obj->trap_run(
        {
            class => "MyTestRun",
            args =>
            [
            test_files =>
            [
                "t/sample-tests/one-ok.t",
                "t/sample-tests/one-fail.t"
            ],
            individual_test_file_verdict_colors =>
            {
                success => "yellow",
                failure => "blue",
                dubious => "magenta",
            },
            ],
        }
        );

    my $color = color("magenta");
    my $reset = color("reset");

    # TEST
    $got->field_like ("stdout", qr/\Q${color}\Edubious\Q${reset}\E/,
        "dubious colored."
    );
}
