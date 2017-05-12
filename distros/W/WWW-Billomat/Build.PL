use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Billomat',
    license             => 'perl',
    dist_author         => q{Aldo Calpini <dada@perl.it>},
    dist_version_from   => 'lib/WWW/Billomat.pm',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.010,
        'Moose' => 0,
        'MooseX::ClassAttribute' => 0,
        'REST::Client' => 0,
        'JSON' => 0,
    },
    add_to_cleanup      => [ 'WWW-Billomat-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            repository => 'https://github.com/dada/WWW-Billomat',
        },
    },
);

$builder->create_build_script();
