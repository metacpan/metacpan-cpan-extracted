use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'WWW-Expand-More',
    module_name         => 'WWW::Expand::More',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/WWW/Expand/More.pm',
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
        'Furl' => 0,
    },
    script_files        => [ 'script/expand_url' ],
    add_to_cleanup      => [ 'WWW-Expand-More-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/WWW-Expand-More',
        bugtracker  => 'http://github.com/bayashi/WWW-Expand-More/issues',
        x_IRC       => {
            url => 'irc://chat.freenode.org/#bayadev',
            web => 'http://webchat.freenode.net/?channels=%23bayadev',
        },
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
