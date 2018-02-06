use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Text-VerticalTable',
    module_name         => 'Text::VerticalTable',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Text/VerticalTable.pm',
    add_to_cleanup      => [ 'Text-VerticalTable-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Text-VerticalTable',
        bugtracker  => 'http://github.com/bayashi/Text-VerticalTable/issues',
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
