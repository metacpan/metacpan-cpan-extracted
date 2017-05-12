use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'USB::Descriptor',
    license             => 'bsd',
    dist_author         => q{Brandon Fosdick <bfoz@bfoz.net>},
    dist_version        => '4',
    build_requires => {
        'Test::More' => 0,
    },
    configure_requires => { 'Module::Build' => 0.38 },
    requires => {
        'perl' => 5.010,
    },
    add_to_cleanup      => [ 'USB-Descriptor-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
