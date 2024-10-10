# This file is under the MIT X11 License:
# http://www.opensource.org/licenses/mit-license.php

use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir( File::Spec->curdir(), "inc" );

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    module_name        => "Test::Run",
    configure_requires => { 'Module::Build' => '0.36', },
    build_requires     => {
        "Test::Trap" => 0,
    },
    requires => {
        'File::Spec'                => 0.6,
        'IPC::System::Simple'       => '1.21',
        'List::Util'                => 0,
        'List::MoreUtils'           => 0,
        'Moose'                     => 0,
        'MooseX::StrictConstructor' => 0,
        'MRO::Compat'               => 0,
        'Scalar::Util'              => 0,
        'TAP::Parser'               => "3.09",
        'Test::Harness'             => "2.53",
        'Text::Sprintf::Named'      => '0.02',
        'UNIVERSAL::require'        => 0,
        'perl'                      => '5.008',
    },
    dist_version_from  => "lib/Test/Run/Core.pm",
    license            => "mit",
    create_makefile_pl => 'traditional',
    meta_merge         => {
        resources => {
            repository => "https://github.com/shlomif/perl-test-run",
            homepage   => "http://web-cpan.shlomifish.org/modules/Test-Run/",
        },
        keywords => [
            "back-end",     "harness",
            "prove",        "qa",
            "QA",           "quality assurance",
            "run",          "runprove",
            "tap",          "TAP",
            "TAP::Harness", "test",
            "testing",
        ],
    },

);

$build->create_build_script;

