use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Test-NoOverride',
    module_name         => 'Test::NoOverride',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Test/NoOverride.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
    },
    requires => {
        'perl' => '5.008001',
        'Module::Functions' => 0,
        'Test::More' => 0.88,
    },
    add_to_cleanup      => [ 'Test-NoOverride-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Test-NoOverride',
        bugtracker  => 'http://github.com/bayashi/Test-NoOverride/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
