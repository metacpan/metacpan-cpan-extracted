# This file is under the MIT X11 License:
# http://www.opensource.org/licenses/mit-license.php

use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    module_name => "Test::Run::CmdLine",
    dist_author => 'Shlomi Fish <shlomif@cpan.org>',
    configure_requires =>
    {
        'Module::Build' => 0.36,
    },
    build_requires =>
    {
        "Test::Trap" => 0,
        'Test::More' => 0,
    },
    requires =>
    {
        'Moose' => 0,
        'MooseX::Getopt' => 0.26,
        'MooseX::Getopt::Basic' => 0,
        'Test::Run::Core' => "0.0126",
        'UNIVERSAL::require' => 0,
        'YAML::XS' => 0,
        'parent' => 0,
        'perl' => '5.008',
    },
    dist_version_from => 'lib/Test/Run/CmdLine.pm',
    license => "mit",
    script_files => [ "bin/runprove", ],
    create_makefile_pl => "traditional",
    meta_merge =>
    {
        resources =>
        {
            homepage => "http://web-cpan.berlios.de/modules/Test-Run/",
            repository => "https://bitbucket.org/shlomif/perl-test-run",
        },
        keywords =>
        [
            "cmdline",
            "command-line",
            "front-end",
            "harness",
            "prove",
            "qa",
            "QA",
            "quality assurance",
            "run",
            "runprove",
            "tap",
            "TAP",
            "TAP::Harness",
            "test",
            "testing",
            "Test::Run",
        ],
    },
);

$build->create_build_script;

