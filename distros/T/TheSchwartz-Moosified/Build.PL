use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'TheSchwartz::Moosified',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/TheSchwartz/Moosified.pm',
    build_requires => {
        'Test::More' => 0,
        'Moose' => '0.79',
        'DBI' => 0,
        'Scalar::Util' => 0,
    },
    add_to_cleanup      => [ 'TheSchwartz-Moosified-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
