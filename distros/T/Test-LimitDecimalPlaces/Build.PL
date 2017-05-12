use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name              => 'Test-LimitDecimalPlaces',
    module_name       => 'Test::LimitDecimalPlaces',
    license           => 'perl',
    dist_author       => 'moznion <moznion@gmail.com>',
    dist_version_from => 'lib/Test/LimitDecimalPlaces.pm',
    dynamic_config    => 0,
    build_requires    => {
        'Test::More'            => '0.98',
        'Test::Exception'       => '0.31',
        'Test::Builder::Tester' => '1.22',
    },
    configure_requires => { 'Module::Build' => '0.40' },
    requires           => {
        perl            => '5.008001',
        'parent'        => 0,
        'Carp'          => 0,
        'Exporter'      => 0,
        'Test::Builder' => '0.98',
    },
    no_index   => { 'directory' => ['inc'] },
    meta_merge => {
        'resources' => {
            'license' => 'http://dev.perl.org/licenses/',
            'repository' =>
              'git://github.com/moznion/Test--LimitDecimalPlaces.git'
        },
    },
    test_files => ( -d '.git' || $ENV{RELEASE_TESTING} )
    ? [qw(t/ xt/)]
    : ['t/'],
    recursive_test_files => 1,
    add_to_cleanup       => ['Test-LimitDecimalPlaces-*'],
    create_readme        => 1,
    create_license       => 1,
);

$builder->create_build_script();
