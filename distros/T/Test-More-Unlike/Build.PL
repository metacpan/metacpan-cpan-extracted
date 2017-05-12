use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Test-More-Unlike',
    module_name         => 'Test::More::Unlike',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Test/More/Unlike.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
    },
    requires => {
        'perl' => '5.008001',
        'strict' => 0,
        'warnings' => 0,
        'Test::More' => 0.88,
        'Text::MatchedPosition' => 0.03,
    },
    add_to_cleanup      => [ 'Test-More-Unlike-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Test-More-Unlike',
        bugtracker  => 'http://github.com/bayashi/Test-More-Unlike/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
