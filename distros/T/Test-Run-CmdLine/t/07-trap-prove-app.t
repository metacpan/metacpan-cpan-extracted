#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;
use File::Spec;
use File::Path;
use Config;
use Cwd;

use Test::Run::CmdLine::Trap::ProveApp;

my $abs_cur = getcwd();
my $alterr_filename = File::Spec->catfile($abs_cur, "alterr.txt");

my $blib = File::Spec->catfile( File::Spec->curdir, "blib" );
my $t_dir = File::Spec->catfile( File::Spec->curdir, "t" );
my $lib = File::Spec->catfile( $blib, "lib" );
my $abs_lib = Cwd::abs_path($lib);
my $runprove = File::Spec->catfile( $blib, "script", "runprove" );
my $abs_runprove = Cwd::abs_path($runprove);
my $sample_tests_dir = File::Spec->catfile("t", "sample-tests");
my $test_file = File::Spec->catfile($sample_tests_dir, "one-ok.t");
my $several_oks_file = File::Spec->catfile($sample_tests_dir, "several-oks.t");

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
        my $got = Test::Run::CmdLine::Trap::ProveApp->trap_run(
            {
                cmdline => [$test_file, $several_oks_file],
            }
        );

        # TEST
        $got->field_like("stdout", qr/All tests successful\./,
            "Good results from runprove");
    }
}
1;

