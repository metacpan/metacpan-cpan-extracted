use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tie::Array::Cavity',
    license             => 'perl',
    dist_author         => q{DULAUNOY Fabrice <fabrice@dulaunoy.com>},
    dist_version_from   => 'lib/Tie/Array/Cavity.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    create_readme => 1,
    add_to_cleanup      => [ 'Tie-Array-Cavity-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
