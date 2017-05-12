use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Mock::Furl',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Test/Mock/Furl.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Test::AllModules' => 0.11,
    },
    requires => {
        'perl' => '5.008001',
        'Test::MockObject' => 0,
        'parent' => 0,
        'Exporter' => 0,
        'Furl' => 0,
    },
    add_to_cleanup      => [ 'Test-Mock-Furl-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Test-Mock-Furl'
      }
    },
    recursive_test_files => 1,
);

$builder->create_build_script();
