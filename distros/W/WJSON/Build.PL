use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WJSON',
    license             => 'Artistic_2',
    dist_author         => q{Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>},
    dist_version_from   => 'lib/WJSON.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Moose' => 0,
        'JSON' => 0,
        'Encode' => 0,
        'Tie::IxHash' => 0
    },
    add_to_cleanup     => [ 'WJSON-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
