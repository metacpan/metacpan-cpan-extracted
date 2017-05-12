use strict;
use warnings;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;


my $builder = Test::Run::Builder->new(
    module_name         => 'Test::Run::Plugin::BreakOnFailure',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/Test/Run/Plugin/BreakOnFailure.pm',
    configure_requires => {
        'Module::Build' => '0.39',
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Trap' => 0,
        'Test::Run::CmdLine::Trap::ProveApp' => 0,
    },
    requires => {
        'perl' => '5.008',
        'Test::Run::CmdLine' => "0.0120",
        'Test::Run::Core' => "0.0120",
        'MRO::Compat' => 0,
        'Moose' => 0,
    },
    test_requires => {
        'YAML::XS' => 0,
    },
    add_to_cleanup      => [ 'Test-Run-Plugin-BreakOnFailure-*' ],
    create_makefile_pl => 'traditional',
    meta_merge =>
    {
        resources =>
        {
            homepage => "http://web-cpan.shlomifish.org/modules/Test-Run/",
            repository => "https://bitbucket.org/shlomif/perl-test-run",
        },
    },
);

$builder->create_build_script();
