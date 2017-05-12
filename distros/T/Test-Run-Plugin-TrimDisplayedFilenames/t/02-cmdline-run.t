#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Config;
use File::Spec;
use Cwd;

use YAML::XS ();

use Test::Run::CmdLine::Trap::ProveApp;

my $alterr_filename = "alterr.txt";

my $blib = File::Spec->catfile( File::Spec->curdir, "blib" );
my $t_dir = File::Spec->catfile( File::Spec->curdir, "t" );
my $lib = File::Spec->catfile( $blib, "lib" );
my $abs_lib = Cwd::abs_path($lib);
my $sample_tests_dir = File::Spec->catfile("t", "sample-tests", "really-really-really-long-dir-name");
my $one_ok_file = File::Spec->catfile($sample_tests_dir, "one-ok.t");
my $several_oks_file = File::Spec->catfile($sample_tests_dir, "several-oks.t");

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
    delete($ENV{'HARNESS_TRIM_FNS'});

    $ENV{'HARNESS_PLUGINS'} = "TrimDisplayedFilenames";

    {
        local $ENV{'HARNESS_TRIM_FNS'} = "fromre:long";

        my $got = Test::Run::CmdLine::Trap::ProveApp->trap_run(
            {
                cmdline =>
                [
                    $one_ok_file,
                    $several_oks_file,
                ],
            }
        );

        # TEST
        $got->field_like("stdout", qr/^one-ok \.{2}/ms,
            "one-ok.t appears alone without the long path."
        );

        # TEST
        $got->field_like("stdout", qr/^several-oks \.{2}/ms,
            "several-oks.t appears alone without the long path."
        );
    }
}

