use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'relative',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/relative.pm',
    requires => {
        'UNIVERSAL::require' => 0,
    },
    build_requires => {
        'Test::More'    => 0,
    },
    add_to_cleanup      => [ 'relative-*' ],
);

$builder->create_build_script();
