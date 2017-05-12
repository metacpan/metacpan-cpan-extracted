use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Weebly',
    license             => 'artistic_2',
    dist_author         => q{Rishwanth Yeddula <ryeddula@cpan.org>},
    dist_version_from   => 'lib/WWW/Weebly.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'URI::Escape' => 0,
        'HTTP::Tiny'  => 0,
    },
    add_to_cleanup     => [ 'WWW-Weebly-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
