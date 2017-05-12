#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;

use Test::Run::Obj;
use Test::Run::Trap::Obj;
use Test::Run::Obj::TotObj;
use Cwd;
use POSIX ();
use List::Util ();
use File::Path ();

{
    my $got = Test::Run::Trap::Obj->trap_run({
            args => [test_files => ["t/sample-tests/simple"]]
        });

    # TEST
    $got->field_like("stdout", qr/All tests successful\./,
        "simple - 'All tests successful.' string as is"
    );

    # TEST
    $got->field_like("stdout",
        qr/^Files=\d+, Tests=\d+,  [^\n]*wallclock secs/m,
        "simple - Final Stats line matches format."
    );
}

# Run several tests.
{
    my $got = Test::Run::Trap::Obj->trap_run({
        args =>
        [
            test_files =>
            [
                "t/sample-tests/simple",
                "t/sample-tests/head_end",
                "t/sample-tests/todo",
            ],
        ]
    });

    # TEST
    $got->field_like("stdout", qr/All tests successful/,
        "simple+head_end+todo - 'All tests successful' (without the period) string as is"
    );
}

# Skipped sub-tests
{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files =>
            [
                "t/sample-tests/simple",
                "t/sample-tests/skip",
            ],
        ]
    });

    # TEST
    $got->field_like(
        "stdout",
        qr/All tests successful, 1 subtest skipped\./,
        "1 subtest skipped with a comma afterwards."
    );
}

# Run several tests with debug.
{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files =>
            [
                "t/sample-tests/simple",
                "t/sample-tests/head_end",
                "t/sample-tests/todo",
            ],
            Debug => 1,
        ]
    });

    # TEST
    $got->field_like("stdout", qr/All tests successful/,
        "In debug - 'All tests successful' (without the period) string as is");
    # TEST
    $got->field_like("stdout", qr/^# PERL5LIB=/m,
        "In debug - Matched a Debug diagnostics");
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files =>
            [
                "t/sample-tests/bailout",
            ],
        ]
    });

    my $match = 'FAILED--Further testing stopped: GERONIMMMOOOOOO!!!';
    # TEST
    $got->field_like("die", ('/' . quotemeta($match) . '/'),
        "Bailout - Matched the bailout error."
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files =>
            [
                "t/sample-tests/skip",
            ],
        ]
    });

    # TEST
    $got->field_like("stdout",
        qr{t/sample-tests/skip \.+ ok\n {8}1/5 skipped: rain delay\n},
        "skip - Matching the skipped line."
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files =>
            [
                "t/sample-tests/todo",
            ],
        ]
    });

    # TEST
    $got->field_like("stdout",
        qr{t/sample-tests/todo \.+ ok\n {8}1/5 unexpectedly succeeded\n},
        "Todo only - Matching the bonus line."
    );


    # TEST
    $got->field_like("stdout",
        qr{^\QAll tests successful (1 subtest UNEXPECTEDLY SUCCEEDED).\E\n}sm,
        "Todo only - Testing for a good summary line"
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files =>
            [
                "t/sample-tests/skip_and_todo",
            ],
        ]
    });

    # TEST
    $got->field_like("stdout",
        qr{t/sample-tests/skip_and_todo \.+ ok\n {8}1/6 skipped: rain delay, 1/6 unexpectedly succeeded\n},
        "skip_and_todo - Matching the bonus+skip line."
    );

    # TEST
    $got->field_like("stdout",
        qr{^\QAll tests successful (1 subtest UNEXPECTEDLY SUCCEEDED), 1 subtest skipped.\E\n}m,
        "skip_and_todo - Testing for a good summary line"
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files =>
            [
                "t/sample-tests/skipall",
            ],
        ]
    });

    # TEST
    $got->field_like(
        "stdout",
        qr{t/sample-tests/skipall \.+ skipped\n {8}all skipped: rope\n},
        "skipall - Matching the all skipped with the reason."
        );
    # TEST
    $got->field_like(
        "stdout",
        qr{^All tests successful, 1 test skipped\.\n}m,
        "skipall - Matching the skipall summary line."
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files =>
            [
                "t/sample-tests/simple_fail",
            ],
        ]
    });

    # TEST
    $got->field_like("stdout",
        qr{t/sample-tests/simple_fail \.+ FAILED tests 2, 5\n\tFailed 2/5 tests, 60.00% okay},
        "simple_fail - Matching the FAILED test report"
        );
    # TEST
    $got->field_like("die",
        qr{^Failed 1/1 test scripts, 0.00% okay\. 2/5 subtests failed, 60\.00% okay\.$}m,
        "simple_fail - Matching the Failed summary line."
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files =>
            [
                "t/sample-tests/invalid-perl",
            ],
        ]
    });

    # TEST
    $got->field_like("die",
        qr{FAILED--1 test script could be run, alas--no output ever seen},
        "Checking for the string in \"no output ever seen\""
        );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files =>
            [
                "t/sample-tests/head_fail",
            ],
        ]
    });

    # TEST
    $got->field_is_deeply("warn", [],
        "Checking for no warnings on failure"
        );
}

sub get_max_system_path_len
{
    my $MIN_VAL = 120;

    # Some systems don't support PATH_MAX, especially some Windows compilers.
    # See http://www.cpantesters.org/cpan/report/cfafb504-7709-1014-9112-f72c93e8ee67
    return List::Util::min(
        $MIN_VAL,
        scalar(eval { POSIX::PATH_MAX(); } || $MIN_VAL)
    );
}

# Test with an exceptionally long path.
{
    my $max_path = get_max_system_path_len();

    # Generate a long enough path so it will overflow the screen.
    my $test_file_path = "sample-tests/simple_fail";
    my $path_lengthening_magic = "../t/";
    my $path_prefix = "t/";
    my $path = "";

    # Construct the path itself.
    {
        $path .= $path_prefix;

        $path .= $path_lengthening_magic x
            (($max_path - length($test_file_path) - length($path_prefix))
                /
             length($path_lengthening_magic)
            );

        $path .= $test_file_path;
    }

    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files =>
            [
                $path,
            ],
        ]
    });

    # TEST
    $got->field_like("die",
        qr{^Failed 1/1 test scripts, 0.00% okay\. 2/5 subtests failed, 60\.00% okay\.$}m,
        "Checking for no errors on excpetionally long test file path"
        );
}

# Test the leaked dir feature.
{
    my $sample_tests_dir = File::Spec->catdir("t", "sample-tests");
    my $leaked_files_dir = File::Spec->catdir($sample_tests_dir, "leaked-files-dir");
    my $leaked_file = File::Spec->catfile($leaked_files_dir, "hello.txt");

    my $leak_test_file = File::Spec->catfile($sample_tests_dir, "leak-file.t");

    mkdir($leaked_files_dir, 0777);
    {
        {
            local (*O);
            open O, ">", $leaked_file;
            print O "This is the file hello.txt";
            close(O);
        }
    }

    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files =>
            [
                $leak_test_file
            ],
            Leaked_Dir => $leaked_files_dir,
        ]
    });

    # Ending the regex with a "$" does not appear to please perl-5.8.8
    # and perl-5.8.x below it. Converting to a \n.
    # TEST
    $got->field_like("stdout",
        qr{^LEAKED FILES: new-file\.txt\n}ms,
        "Checking for output of the leaked files."
    );

    File::Path::rmtree($leaked_files_dir);
}

package MyTestRun::Obj::AlwaysTerm;

use Moose;

extends(
    "MyTestRun::Plugin::CmdLine::Output::AlwaysTerm",
    "Test::Run::Core"
);

package MyTestRun::Plugin::CmdLine::Output::AlwaysTerm;

use Moose;

extends(
    "Test::Run::Plugin::CmdLine::Output",
);

sub _get_new_output
{
    my ($self, $args) = @_;

    return MyTestRun::Output::AlwaysTerm->new({ Verbose => $self->Verbose(), NoTty => $self->NoTty()});
}

package MyTestRun::Output::AlwaysTerm;

use Moose;

extends(
    "Test::Run::Output"
);

sub _is_terminal { return 1; }

package main;

{
    my $got = Test::Run::Trap::Obj->trap_run({
        class => "MyTestRun::Obj::AlwaysTerm",
        args => [test_files => ["t/sample-tests/simple"]],
    });

    # TEST
    $got->field_like("stdout",
        qr{\r +\r},
        "Check for leader in terminal output."
    );
}

__END__

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

