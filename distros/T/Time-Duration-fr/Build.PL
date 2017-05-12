use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Time::Duration::fr',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/Time/Duration/fr.pm',
    meta_merge          => {
        resources       => {
            repository  => 'http://github.com/maddingue/Time-Duration-fr',
        },
    },
    requires => {
        'Exporter'          => 0,
        'Time::Duration'    => 0,
    },
    build_requires => {
        'Test::More'        => 0,
    },
    add_to_cleanup      => [ 'Time-Duration-fr-*' ],
);

$builder->create_build_script();
