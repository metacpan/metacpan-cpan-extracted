use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::NoLoad',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Test/NoLoad.pm',
    requires => {
        'perl' => '5.8.1',
        'Test::More' => 0.88,
        'Exporter' => 0,
    },
    add_to_cleanup      => [ 'Test-NoLoad-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Test-NoLoad'
      }
    },
    recursive_test_files => 1,
);

$builder->create_build_script();
