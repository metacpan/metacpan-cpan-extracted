#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;

use Test::Run::Obj;
use Test::Run::Plugin::AlternateInterpreters;

use Test::Run::Trap::Obj;

package MyTestRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Plugin::AlternateInterpreters Test::Run::Obj));

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
                    "t/sample-tests/success1.cat",
                    "t/sample-tests/one-ok.t"
                ],
                alternate_interpreters =>
                [
                    {
                        cmd =>
                        ("$^X " . File::Spec->catfile(
                            File::Spec->curdir(), "t", "data",
                            "interpreters", "cat.pl"
                            ) . " "
                        ),
                        type => "regex",
                        pattern => '\.cat$',
                    },
                ],
            ]
        }
        );

    # TEST
    $got->field_like("stdout", qr/All tests successful\./,
        "All test are successful with multiple interpreters"
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
                    "t/sample-tests/success2.mok.cat",
                    "t/sample-tests/success1.cat",
                    "t/sample-tests/one-ok.t",
                    "t/sample-tests/success1.mok",
                ],
                alternate_interpreters =>
                [
                    {
                        cmd =>
                        ("$^X " . File::Spec->catfile(
                            File::Spec->curdir(), "t", "data",
                            "interpreters", "mini-ok.pl"
                            ) . " "
                        ),
                        type => "regex",
                        pattern => '\.mok(?:\.cat)?\z',
                    },
                    {
                        cmd =>
                        ("$^X " . File::Spec->catfile(
                            File::Spec->curdir(), "t", "data",
                            "interpreters", "cat.pl"
                            ) . " "
                        ),
                        type => "regex",
                        pattern => '\.cat\z',
                    },
                ],
            ],
        }
    );

    # TEST
    $got->field_like("stdout", qr/All tests successful\./,
        "Tests over-riding order is applied.");
}

