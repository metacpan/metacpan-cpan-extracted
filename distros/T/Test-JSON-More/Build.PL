use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Test-JSON-More',
    module_name         => 'Test::JSON::More',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Test/JSON/More.pm',
    add_to_cleanup      => [ 'Test-JSON-More-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Test-JSON-More',
        bugtracker  => 'http://github.com/bayashi/Test-JSON-More/issues',
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
