use strict;
use warnings;

use Module::Build::Using::PkgConfig;

my $build = Module::Build::Using::PkgConfig->new(
    module_name => 'UV',
    requires => {
        'perl' => '5.014',

        'Carp' => 0,
        'Exporter' => '5.57',
        'Scalar::Util' => 0,
        'XSLoader' => '0.13',
    },
    configure_requires => {
        'Module::Build' => '0.4004', # test_requires
    },
    test_requires => {
        'Test::More' => '0.88', # done_testing
    },
    license => 'perl',
    create_license => 1,
    create_readme  => 1,
    meta_merge => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'git://github.com/p5-UV/p5-UV.git',
                web  => 'https://github.com/p5-UV/p5-UV',
            },
            bugtracker => {
                web => 'https://github.com/p5-UV/p5-UV/issues',
            },
        },
    },
    extra_compiler_flags => [qw( -Ihax )],
);

$build->use_pkgconfig( "libuv",
    atleast_version => "1.32",

    alien         => "Alien::libuv",
    alien_version => "1.013", # contains libuv 1.34.2
);

$build->create_build_script;
