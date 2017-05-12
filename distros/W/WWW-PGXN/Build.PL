use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'WWW::PGXN',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.30' },
    build_requires     => {
        'File::Spec::Functions' => 0,
        'Module::Build'         => '0.30',
        'Test::MockModule'      => '0.05',
        'Test::More'            => '0.96',
    },
    requires => {
        'Carp'          => 0,
        'File::Spec'    => 0,
        'HTTP::Tiny'    => 0,
        'JSON'          => 0,
        'perl'          => 5.010,
        'URI::Template' => '0.16',
    },
    recommends => {
        'Test::Pod'           => '1.41',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/WWW-PGXN/',
            bugtracker => 'http://github.com/theory/www-pgxn/issues/',
            repository => 'http://github.com/theory/www-pgxn/tree/',
        }
    },
)->create_build_script;
