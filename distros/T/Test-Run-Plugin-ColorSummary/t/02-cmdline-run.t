#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use Term::ANSIColor;
use Config;
use File::Spec;
use Cwd;

use Test::Run::CmdLine::Trap::ProveApp;

my $blib = File::Spec->catfile( File::Spec->curdir, "blib" );
my $t_dir = File::Spec->catfile( File::Spec->curdir, "t" );
my $lib = File::Spec->catfile( $blib, "lib" );
my $abs_lib = Cwd::abs_path($lib);
my $sample_tests_dir = File::Spec->catfile("t", "sample-tests");
my $test_file = File::Spec->catfile($sample_tests_dir, "one-ok.t");
my $several_oks_file = File::Spec->catfile($sample_tests_dir, "several-oks.t");
my $one_fail_file = File::Spec->catfile($sample_tests_dir, "one-fail.t");

{
    local %ENV = %ENV;

    $ENV{'PERL5LIB'} = $abs_lib.$Config{'path_sep'}.$ENV{'PERL5LIB'};
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
    delete($ENV{'HARNESS_SUMMARY_COLOR_SUCCESS'});
    delete($ENV{'HARNESS_SUMMARY_COLOR_FAIL'});

    $ENV{'HARNESS_PLUGINS'} = "ColorSummary";

    {
        my $got = Test::Run::CmdLine::Trap::ProveApp->trap_run(
            {
                cmdline => [$test_file, $several_oks_file],
            }
        );

        my $color = color("bold blue");

        # TEST
        $got->field_like("stdout",
            qr/\Q${color}\EAll tests successful\./,
            "'All tests successful.' string as is"
        );
    }

    {
        my $got = Test::Run::CmdLine::Trap::ProveApp->trap_run(
            {
                cmdline => [$one_fail_file],
            }
        );
        my $color = color("bold red");

        # TEST
        $got->field_like("stderr", qr/\Q${color}\EFailed 1\/1 test scripts/,
            qq{Found colored "Failed 1/1" string}
        );
    }
    {
        local $ENV{'HARNESS_SUMMARY_COLOR_SUCCESS'} = "green";
        local $ENV{'HARNESS_SUMMARY_COLOR_FAIL'} = "yellow";
        my $got = Test::Run::CmdLine::Trap::ProveApp->trap_run(
            {
                cmdline => [$test_file, $several_oks_file],
            }
        );

        my $color = color("green");

        # TEST
        $got->field_like("stdout",
            qr/\Q${color}\EAll tests successful\./,
            "'All tests successful.' string in user-speced color"
        );
    }
    {
        local $ENV{'HARNESS_SUMMARY_COLOR_SUCCESS'} = "green";
        local $ENV{'HARNESS_SUMMARY_COLOR_FAIL'} = "yellow";
        my $got = Test::Run::CmdLine::Trap::ProveApp->trap_run(
            {
                cmdline => [$one_fail_file],
            }
        );

        my $color = color("yellow");

        # TEST
        $got->field_like("stderr",
            qr/\Q${color}\EFailed 1\/1 test scripts/,
            qq{Found colored "Failed 1/1" string with user-specified color}
        );
    }
}

