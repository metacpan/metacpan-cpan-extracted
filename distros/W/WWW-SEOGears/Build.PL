use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::SEOGears',
    license             => 'artistic_2',
    dist_author         => q{Rishwanth Yeddula <ryeddula@cpan.org>},
    dist_version_from   => 'lib/WWW/SEOGears.pm',
    release_status      => 'stable',
    meta_merge => {
        resources => {
            repository => 'https://github.com/ryeddula/www-seogears',
        }
    },
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'HTTP::Tiny'           => '0.029',
        'Net::SSLeay'          => '1.49',
        'URI::Escape'          => 0,
        'Date::Calc'           => 0,
        'JSON'                 => 0,
        'URI::Escape'          => 0,
    },
    add_to_cleanup     => [ 'WWW-SEOGears-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
