use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'say',
    module_name         => 'say',
    license             => 'artistic_2',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/say.pm',
    add_to_cleanup      => [ 'say-*' ],
    no_index => {
        directory => [ 't', 'xt', 'share' ],
    },
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/say',
        bugtracker  => 'http://github.com/bayashi/say/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1,
);

$builder->create_build_script();
