use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'WebService-BitFlyer',
    module_name         => 'WebService::BitFlyer',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/WebService/BitFlyer.pm',
    add_to_cleanup      => [ 'WebService-BitFlyer-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/WebService-BitFlyer',
        bugtracker  => 'http://github.com/bayashi/WebService-BitFlyer/issues',
        x_IRC       => {
            url => 'irc://chat.freenode.org/#bayadev',
            web => 'http://webchat.freenode.net/?channels=%23bayadev',
        },
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1,
);

$builder->create_build_script();
