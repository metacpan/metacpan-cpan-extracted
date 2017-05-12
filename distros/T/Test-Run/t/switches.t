#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use File::Spec;
use Test::Run::Trap::Obj;

my $switches = "-I" . File::Spec->catdir(File::Spec->curdir(), "t", "test-libs", "lib1");
my $switches_lib2 = "-I" . File::Spec->catdir(File::Spec->curdir(), "t", "test-libs", "lib2");


# Test Switches()
{
    my $got = Test::Run::Trap::Obj->trap_run(
        {
            args =>
            [
                test_files => ["t/sample-tests/with-myhello"],
                Switches => $switches,
            ],
        }
    );

    # TEST
    $got->field_like("stdout", qr/All tests successful\./,
        "with-myhello - 'All tests successful.' string as is"
    );
}

# Test Switches_Env()
{
    my $got = Test::Run::Trap::Obj->trap_run(
        {
            args =>
            [
                test_files => ["t/sample-tests/with-myhello"],
                Switches_Env => $switches,
            ]
        }
    );

    # TEST
    $got->field_like("stdout", qr/All tests successful\./,
        "With Switches_Env - 'All tests successful.' string as is"
    );
}

# Test both Switches() and Switches_Env().
{
    my $got = Test::Run::Trap::Obj->trap_run(
        {
            args =>
            [
                test_files => ["t/sample-tests/with-myhello-and-myfoo"],
                Switches => $switches_lib2,
                Switches_Env => $switches,
            ],
        }
    );

    # TEST
    $got->field_like("stdout",
        qr/All tests successful\./,
        "With Switches and Switches_Env - 'All tests successful.' string as is"
    );
}

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

