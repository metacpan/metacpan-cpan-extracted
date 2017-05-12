use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Wordnik::API',
    license             => 'gpl3',
    dist_author         => 'Pedro Silva <pedros@berkeley.edu>',
    dist_version_from   => 'lib/WWW/Wordnik/API.pm',
    requires => {
        'Test::More'       => 0,
        'version'          => 0,
        'Carp'             => 0,
        'LWP::UserAgent'   => 0,
    },
    recommends => {
        'JSON'             => 0,
    },
    add_to_cleanup      => [ 'WWW-Wordnik-API-*' ],
    create_makefile_pl  => 'traditional',
    sign                => 1,
    create_readme       => 1,
    create_license      => 1,
);

$builder->create_build_script();
