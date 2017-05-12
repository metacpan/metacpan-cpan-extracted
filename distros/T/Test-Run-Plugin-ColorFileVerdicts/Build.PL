use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Test::Run::Plugin::ColorFileVerdicts',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/Test/Run/Plugin/ColorFileVerdicts.pm',
    configure_requires =>
    {
        'Module::Build' => 0.36,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Run::Trap::Obj' => 0,
        'Test::Run::CmdLine::Trap::ProveApp' => 0,
    },
    requires => {
        "Moose" => 0,
        "MRO::Compat" => 0,
        "Term::ANSIColor" => 0,
        "Test::Run::Core" => "0.0122",
        "Test::Run::CmdLine" => "0.0121",
        "perl" => '5.008',
    },
    meta_merge =>
    {
        resources =>
        {
            homepage => "http://web-cpan.shlomifish.org/modules/Test-Run/",
            repository => "https://bitbucket.org/shlomif/perl-test-run",
        },
    },
    add_to_cleanup      => [ 'Test-Run-Plugin-ColorFileVerdicts-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
