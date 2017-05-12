use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'WWW-Sitemap-Simple',
    module_name         => 'WWW::Sitemap::Simple',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/WWW/Sitemap/Simple.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Test::Output' => 0,
        'File::Temp' => 0,
    },
    requires => {
        'perl' => '5.008001',
        'Carp' => 0,
        'Class::Accessor::Lite' => 0.05,
        'Digest::MD5' => 0,
        'IO::File' => 0,
        'Compress::Zlib' => 0,
        'IO::Zlib' => 0,
    },
    add_to_cleanup      => [ 'WWW-Sitemap-Simple-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/WWW-Sitemap-Simple',
        bugtracker  => 'http://github.com/bayashi/WWW-Sitemap-Simple/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
