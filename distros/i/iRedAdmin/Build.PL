use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'iRedAdmin',
    license             => 'artistic_2',
    dist_author         => q{Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>},
    dist_version_from   => 'lib/iRedAdmin.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Moo' => 0,
        'Email::Valid' => 0,
        'Encode' => 0,
        'WWW::Mechanize' => 0,
        'HTTP::Cookies' => 0,
    },
    add_to_cleanup     => [ 'iRedAdmin-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
