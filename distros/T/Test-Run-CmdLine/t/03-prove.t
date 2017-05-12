#!/usr/bin/perl -w

use strict;

use Test::More tests => 39;
use File::Spec;
use File::Path;
use Config;
use Cwd;

use Test::Run::CmdLine::Trap::Prove;

my $abs_cur = getcwd();
my $alterr_filename = File::Spec->catfile($abs_cur, "alterr.txt");

my $blib = File::Spec->catdir( File::Spec->curdir, "blib" );
my $t_dir = File::Spec->catdir( File::Spec->curdir, "t" );
my $t_lib_dir = File::Spec->catdir( $t_dir, "lib");
my $lib = File::Spec->catfile( $blib, "lib" );
my $abs_lib = Cwd::abs_path($lib);
my $runprove = File::Spec->catfile( $blib, "script", "runprove" );
my $abs_runprove = Cwd::abs_path($runprove);
my $sample_tests_dir = File::Spec->catfile("t", "sample-tests");
my $test_file = File::Spec->catfile($sample_tests_dir, "one-ok.t");
my $with_myhello_file = File::Spec->catfile($sample_tests_dir, "with-myhello");
my $with_myhello_and_myfoo_file = File::Spec->catfile($sample_tests_dir, "with-myhello-and-myfoo");
my $simple_fail_file = File::Spec->catfile($sample_tests_dir, "simple_fail.t");
my $leaked_files_dir = File::Spec->catfile($sample_tests_dir, "leaked-files-dir");
my $several_oks_file = File::Spec->catfile($sample_tests_dir, "several-oks.t");
my $leaked_file = File::Spec->catfile($leaked_files_dir, "hello.txt");
my $leak_test_file = File::Spec->catfile($sample_tests_dir, "leak-file.t");
my $switches_lib1 = "-I" . File::Spec->catdir(File::Spec->curdir(), "t", "test-libs", "lib1");
my $switches_lib2 = "-I" . File::Spec->catdir(File::Spec->curdir(), "t", "test-libs", "lib2");
my $no_t_flags_file = File::Spec->catfile($sample_tests_dir, "no-t-flags.t");
my $lowercase_t_flag_file = File::Spec->catfile($sample_tests_dir, "lowercase-t-flag.t");
my $uppercase_t_flag_file = File::Spec->catfile($sample_tests_dir, "uppercase-t-flag.t");

my $NEW_LINE_RE = qr/\r?\n/;

# This does not work in MS Windows for some reason so I'm trying a different
# approach
# my $OPT_NEW_LINE_RE = qr/(?:$NEW_LINE_RE)?/;

my $OPT_NEW_LINE_RE = qr/\r?\n?/;

# "Real men don't write workarounds. They expect their user to upgrade their
# software" -- Shlomi Fish (= me), who is now officially not a real man.

{
    local %ENV = %ENV;

    local $ENV{'PERL5LIB'} = $abs_lib.$Config{'path_sep'}.$ENV{'PERL5LIB'};
    delete($ENV{'HARNESS_FILELEAK_IN_DIR'});
    delete($ENV{'HARNESS_VERBOSE'});
    delete($ENV{'HARNESS_DEBUG'});
    delete($ENV{'HARNESS_COLUMNS'});
    delete($ENV{'HARNESS_TIMER'});
    delete($ENV{'HARNESS_NOTTY'});
    delete($ENV{'HARNESS_PERL'});
    delete($ENV{'HARNESS_PERL_SWITCHES'});
    delete($ENV{'HARNESS_DRIVER'});
    delete($ENV{'HARNESS_PLUGINS'});
    delete($ENV{'PROVE_SWITCHES'});
    $ENV{'COLUMNS'} = 80;
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => qq{$test_file},
            }
        );

        # TEST
        $got->field_like("stdout", qr/All tests successful\./,
            "Good results from runprove");

        # TEST
        $got->field_is("system_ret", 0,
            "runprove returns a zero exit code upon success."
        );
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => qq{--help},
            }
        );

        # TEST
        $got->field_like("stdout", qr/\Qrunprove [options]\E/,
            "Good results from runprove --help ");

        # TEST
        $got->field_is("system_ret", 0,
            "runprove --help returns a zero exit code upon success."
        );
    }

    {
        mkdir($leaked_files_dir, 0777);
        open O, ">", $leaked_file;
        print O "This is the file hello.txt";
        close(O);

        local $ENV{'HARNESS_FILELEAK_IN_DIR'} = $leaked_files_dir;

        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$leak_test_file $test_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/${NEW_LINE_RE}LEAKED FILES: new-file.txt${NEW_LINE_RE}/,
            "Checking for files that were leaked");
        rmtree([$leaked_files_dir], 0, 0);
    }

    {
        local $ENV{'HARNESS_VERBOSE'} = 1;

        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => $test_file,
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/^ok 1/m,
            "Testing is 'Verbose' if HARNESS_VERBOSE is 1.");
    }
    {
        # This is a control experiment.
        local $ENV{'HARNESS_VERBOSE'} = 0;
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => $test_file,
            }
        );

        # TEST
        $got->field_unlike ("stdout", qr/^ok 1/m,
            "Testing is not 'Verbose' if HARNESS_VERBOSE is 0."
        );
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => qq{-v $test_file},
            }
        );

        # TEST
        $got->field_like("stdout", qr/^ok 1/m,
            "Testing is 'Verbose' with the '-v' flag."
        );
    }
    {
        local $ENV{'HARNESS_DEBUG'} = 1;
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => $test_file,
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/# Running:/,
            "Testing is 'Debug' if HARNESS_DEBUG is 1.");
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => qq{-d $test_file},
            }
        );

        # TEST
        $got->field_like("stdout", qr/# Running:/,
            "Testing is 'Debug' is the '-d' flag was specified."
        );
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$simple_fail_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/^\-{79}${OPT_NEW_LINE_RE}$/m,
            "Testing that simple fail is formatted for 80 columns");
    }
    {
        local $ENV{'COLUMNS'} = 100;
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$simple_fail_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/^\-{99}${OPT_NEW_LINE_RE}$/m,
            "Testing that simple fail is formatted for 100 columns");
    }
    {
        local $ENV{'HARNESS_COLUMNS'} = 100;
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$simple_fail_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/^\-{99}${OPT_NEW_LINE_RE}$/m,
            "Testing that simple fail is formatted for 100 columns");
    }
    {
        local %ENV = %ENV;
        # delete ($ENV{'COLUMNS'});
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$simple_fail_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/^\-{79}${OPT_NEW_LINE_RE}$/m,
            "Testing that Columns defaults to 80");
    }
    {
        local $ENV{'HARNESS_TIMER'} = 1;
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$test_file $several_oks_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/ok\s+\d+(?:\.\d+)?s${OPT_NEW_LINE_RE}$/m,
            "Displays the time if HARNESS_TIMER is 1.");
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "--timer $test_file $several_oks_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/ok\s+\d+(?:\.\d+)?s${OPT_NEW_LINE_RE}$/m,
            "Displays the time if --timer was set.");
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$test_file $several_oks_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/ok${OPT_NEW_LINE_RE}$/m,
            "Timer control experiment");
    }
    {
        local $ENV{'HARNESS_NOTTY'} = 1;
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$test_file $several_oks_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/All tests successful\./,
            "Good results from HARNESS_NOTTY");
    }
    {
        local $ENV{'HARNESS_PERL'} = $^X;
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$test_file $several_oks_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/All tests successful\./,
            "Good results from HARNESS_PERL");
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "--perl $^X $test_file $several_oks_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/All tests successful\./,
            "Good results with the '--perl' flag");
    }
    {
        local $ENV{'HARNESS_PERL_SWITCHES'} = $switches_lib1;
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$with_myhello_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/All tests successful\./,
            "Good results with the '--perl' flag");
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$switches_lib1 $with_myhello_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/All tests successful\./,
            "Good results with the '--perl' flag");
    }
    {
        local $ENV{'HARNESS_PERL_SWITCHES'} = $switches_lib2;
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$switches_lib1 $with_myhello_and_myfoo_file",
            }
        );

        # TEST
        $got->field_like ("stdout" , qr/All tests successful\./,
            "Good results with the '--perl' flag");
    }
    # Test that it can work around a specified HARNESS_PLUGINS and an
    # unspecified HARNESS_DRIVER.
    {
        local $ENV{'HARNESS_PLUGINS'} = "Super";
        local $ENV{'PERL5LIB'} =
            $t_lib_dir.$Config{'path_sep'}.$ENV{'PERL5LIB'}
            ;

        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$test_file $several_oks_file",
            }
        );

        # TEST
        $got->field_like ("stdout", qr/All tests are super-successful\!/,
            "Good results with the HARNESS_PLUGINS env var alone.");
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "--version",
            }
        );

        # TEST
        $got->field_like ("stdout", qr/runprove v.*using Test::Run v.*Test::Run::CmdLine v.*Perl v/,
            "Good results for the version string");
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$no_t_flags_file",
            }
        );

        # TEST
        $got->field_like ("stdout", qr/All tests successful\./,
            "Good results for the absence of the -t flag");
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "-t $lowercase_t_flag_file",
            }
        );

        # TEST
        $got->field_like ("stdout", qr/All tests successful\./,
            "Good results for the presence of the -t flag");
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "-T $uppercase_t_flag_file",
            }
        );

        # TEST
        $got->field_like ("stdout", qr/All tests successful\./,
            "Good results for the presence of the -T flag");
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "-T $no_t_flags_file",
            }
        );

        # TEST
        $got->field_like ("stdout", qr/FAILED test/,
            "Test that requires no taint fails if -T is specified");
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => "$uppercase_t_flag_file",
            }
        );

        # TEST
        $got->field_like ("stdout", qr/FAILED test/,
            "Good results for the presence of the -T flag");
    }
    {
        my $cwd = Cwd::getcwd();
        chdir(File::Spec->catdir(File::Spec->curdir(), "t", "sample-tests", "with-blib"));

        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $abs_runprove,
                cmdline => "--blib " . File::Spec->catfile(File::Spec->curdir(), "t", "mytest.t"),
            }
        );

        # TEST
        $got->field_like ("stdout", qr/All tests successful\./,
            "Good results for the presence of the --blib flag");
        chdir($cwd);
    }
    {
        my $cwd = Cwd::getcwd();
        chdir(File::Spec->catdir(File::Spec->curdir(), "t", "sample-tests", "with-blib"));

        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $abs_runprove,
                cmdline => "" . File::Spec->catfile(File::Spec->curdir(), "t", "mytest.t"),
            }
        );

        # TEST
        $got->field_like ("stdout", qr/DIED. FAILED test 1/,
            "File fails if it doesn't have --blib where there is a required module");
        chdir($cwd);
    }
    {
        my $cwd = Cwd::getcwd();
        chdir(File::Spec->catdir(File::Spec->curdir(), "t", "sample-tests", "with-lib"));

        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $abs_runprove,
                cmdline => "--lib " . File::Spec->catfile(File::Spec->curdir(), "t", "mytest.t"),
            }
        );

        # TEST
        $got->field_like ("stdout", qr/All tests successful\./,
            "Good results for the presence of the --lib flag");
        chdir($cwd);
    }
    {
        my $cwd = Cwd::getcwd();
        chdir(File::Spec->catdir(File::Spec->curdir(), "t", "sample-tests", "with-lib"));

        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $abs_runprove,
                cmdline => "" . File::Spec->catfile(File::Spec->curdir(), "t", "mytest.t"),
            }
        );

        # TEST
        $got->field_like ("stdout", qr/DIED. FAILED test 1/,
            "File fails if it doesn't have --lib where there is a required module");
        chdir($cwd);
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => qq{--dry $test_file $with_myhello_file},
            }
        );

        # TEST
        $got->field_like("stdout", qr#\A\Q$test_file\E${OPT_NEW_LINE_RE}\Q$with_myhello_file\E${OPT_NEW_LINE_RE}\z#,
            "Testing dry run"
        );
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $runprove,
                cmdline => $simple_fail_file,
            },
        );
        # TEST
        $got->field_unlike("stderr", qr/${NEW_LINE_RE}${NEW_LINE_RE}$/s,
            "Testing that the output does not end with two "
            . "newlines on failure."
        );
    }
    {
        local $ENV{'PROVE_SWITCHES'} = "--lib";
        my $cwd = Cwd::getcwd();
        chdir(File::Spec->catdir(File::Spec->curdir(), "t", "sample-tests", "with-lib"));

        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $abs_runprove,
                cmdline => "" . File::Spec->catfile(File::Spec->curdir(), "t", "mytest.t"),
            }
        );

        # TEST
        $got->field_like ("stdout", qr/All tests successful\./,
            "Good results for the presence of the --lib flag in ENV{PROVE_SWITCHES}");
        chdir($cwd);
    }
    {
        my $got = Test::Run::CmdLine::Trap::Prove->trap_run(
            {
                runprove => $abs_runprove,
                cmdline => "",
            }
        );

        # TEST
        $got->field_is("stdout", "",
            "Empty file list does not croak with weird errors (STDOUT)"
        );
        # TEST
        $got->field_is ("stderr", "",
            "Empty file list does not croak with weird errors (STDERR)"
        );
    }
}
1;

