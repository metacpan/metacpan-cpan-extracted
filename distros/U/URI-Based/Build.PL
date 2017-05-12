use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'URI::Based',
    license             => 'perl',
    dist_author         => q{Nic Wolff <nic@angel.net>},
    dist_version_from   => 'lib/URI/Based.pm',
    configure_requires => { 'Module::Build' => 0.40 },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
	'URI::WithBase' => 0,
    },
    add_to_cleanup      => [ 'URI-Based-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
