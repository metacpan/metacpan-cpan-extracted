#!/usr/bin/perl

use strict;
use warnings;

use Test::Run::Obj;
use Test::Run::Plugin::ColorSummary;
use Test::Run::Trap::Obj;

package MyTestRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Plugin::ColorSummary Test::Run::Obj));

package main;

use Test::More tests => 4;

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
            ],
        }
        );

    my $color = color("bold blue");

    # TEST
    $got->field_like("stdout", qr/\Q${color}\EAll tests successful\./,
        "'All tests successful.' string as is"
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
            ],
            ]
        }
        );

    my $color = color("bold red");

    # TEST
    $got->field_like("die", qr/\Q${color}\EFailed 1\/1 test scripts/,
        qq{Found colored "Failed 1/1" string}
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
                    "t/sample-tests/several-oks.t"
                ],
                summary_color_success => "green",
                summary_color_failure => "yellow",
            ],
        }
        );

    my $color = color("green");

    # TEST
    $got->field_like("stdout", qr/\Q${color}\EAll tests successful\./,
        "Text is colored green on explicity SummaryColor_success"
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
                ],
                summary_color_success => "green",
                summary_color_failure => "yellow",
            ],
        }
        );

    my $color = color("yellow");

    # TEST
    $got->field_like("die", qr/\Q${color}\EFailed 1\/1 test scripts/,
        qq{Found colored "Failed 1/1" string with user-specified color}
    );
}
