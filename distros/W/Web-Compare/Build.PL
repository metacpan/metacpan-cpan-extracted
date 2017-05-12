use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Web-Compare',
    module_name         => 'Web::Compare',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Web/Compare.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Test::Fake::HTTPD' => 0,
        'LWP::UserAgent' => 0,
        'String::Diff' => 0,
    },
    requires => {
        'perl' => '5.008001',
        'strict' => 0,
        'warnings' => 0,
        'HTTP::Request' => 0,
        'Furl' => 0,
        'Diff::LibXDiff' => 0,
        'Class::Accessor::Lite' => 0,
    },
    add_to_cleanup      => [ 'Web-Compare-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Web-Compare',
        bugtracker  => 'http://github.com/bayashi/Web-Compare/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
