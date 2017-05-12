#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

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
my $sample_tests_dir = File::Spec->catfile("t", "sample-tests");
my $suc2_mok_file = File::Spec->catfile($sample_tests_dir, "success2.mok.cat");
my $suc1_cat_file = File::Spec->catfile($sample_tests_dir, "success1.cat");
my $one_ok_file = File::Spec->catfile($sample_tests_dir, "one-ok.t");
my $suc1_mok_file = File::Spec->catfile($sample_tests_dir, "success1.mok");

# Cwd.pm (not the XS version) has a problem referencing a non-existent
# file inside an existing containing directory.
my $_config_file_rel = File::Spec->catfile(
        File::Spec->curdir(), "t", "data", "config-files", "mokcat1.yml",
    );

{
    open my $out, ">", $_config_file_rel
        or die "Could not open $_config_file_rel for writing.";
    print {$out} "";
    close($out);
}

my $config_file = Cwd::abs_path($_config_file_rel);

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

    $ENV{'HARNESS_PLUGINS'} = "AlternateInterpreters";

    {
        local $ENV{'HARNESS_ALT_INTRP_FILE'} = $config_file;

        my $yaml_data =
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
        ];

        YAML::XS::DumpFile($config_file, $yaml_data);

        my $got = Test::Run::CmdLine::Trap::ProveApp->trap_run(
            {
                cmdline =>
                [
                    $suc2_mok_file,$suc1_cat_file, $one_ok_file,
                    $suc1_mok_file
                ],
            }
        );

        # TEST
        $got->field_like("stdout", qr/All tests successful\./,
            "All tests were successful with the new interpreters"
        );
    }
}
