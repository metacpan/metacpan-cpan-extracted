use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::MethodName',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Test/MethodName.pm',
    build_requires      => {
        'FindBin' => 0,
        'File::Spec' => 0,
    },
    requires => {
        'perl' => '5.8.1',
        'Test::More' => 0.88,
        'Module::Pluggable::Object' => 0,
        'List::MoreUtils' => 0,
        'Module::Functions' => '2.1.0',
    },
    add_to_cleanup      => [ 'Test-MethodName-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Test-MethodName'
      }
    },
    recursive_test_files => 1,
);

$builder->create_build_script();
