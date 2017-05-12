use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Text-MatchedPosition',
    module_name         => 'Text::MatchedPosition',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Text/MatchedPosition.pm',
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
        'utf8' => 0,
        'Carp' => 0,
    },
    add_to_cleanup      => [ 'Text-MatchedPosition-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Text-MatchedPosition',
        bugtracker  => 'http://github.com/bayashi/Text-MatchedPosition/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
