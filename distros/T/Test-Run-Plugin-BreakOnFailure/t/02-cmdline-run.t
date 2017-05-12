#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Config;
use File::Spec;
use Cwd;

use Test::Run::CmdLine::Trap::ProveApp;

my $alterr_filename = "alterr.txt";

my $blib = File::Spec->catfile( File::Spec->curdir, "blib" );
my $t_dir = File::Spec->catfile( File::Spec->curdir, "t" );
my $lib = File::Spec->catfile( $blib, "lib" );
my $abs_lib = Cwd::abs_path($lib);
my $sample_tests_dir = File::Spec->catfile("t", "sample-tests");
my $suc2_mok_file = File::Spec->catfile($sample_tests_dir, "success2.mok.cat");
my $suc1_cat_file = File::Spec->catfile($sample_tests_dir, "success1.cat");
my $one_ok_file = File::Spec->catfile($sample_tests_dir, "one-ok.t");
my $suc1_mok_file = File::Spec->catfile($sample_tests_dir, "success1.mok");
my $fail_file = File::Spec->catfile($sample_tests_dir, "one-fail.t");

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
    delete($ENV{'HARNESS_ALT_INTRP_FILE'});
    delete($ENV{'HARNESS_BREAK'});

    $ENV{'HARNESS_PLUGINS'} = "BreakOnFailure";

    {
        my $got = Test::Run::CmdLine::Trap::ProveApp->trap_run(
            {
                cmdline =>
                [
                    $fail_file,
                    $one_ok_file,
                ],
            }
        );

        # TEST
        $got->field_like("stdout", qr/one-ok/,
            "Test not skipped upon unset HARNESS_BREAK"
        );
    }

    {
        local $ENV{'HARNESS_BREAK'} = '1';

        my $got = Test::Run::CmdLine::Trap::ProveApp->trap_run(
            {
                cmdline =>
                [
                    $fail_file,
                    $one_ok_file,
                ],
            }
        );

        # TEST
        $got->field_unlike("stdout", qr/one-ok/,
            "Test breaks on failure upon HARNESS_BREAK."
        );
    }
}

