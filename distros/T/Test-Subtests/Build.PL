use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Subtests',
    license             => 'LGPL_3_0',
    create_license      => 1,
    dist_author         => q{Bert Vanderbauwhede <batlock666@gmail.com>},
    dist_version_from   => 'lib/Test/Subtests.pm',
    dist_abstract       => 'Different kinds of subtests.',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Test::Builder'         => 0,
        'Test::Builder::Module' => 0,
    },
    add_to_cleanup     => [ 'Test-Subtests-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
