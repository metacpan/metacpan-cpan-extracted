use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name         => 'Test::File::Contents',
    license             => 'perl',
    configure_requires  => { 'Module::Build' => '0.30' },
    build_requires     => {
        'Module::Build' => '0.30',
        'Test::More'    => '0.70',
    },
    requires => {
        'Test::Builder' => '0.70',
        'Digest::MD5'   => 0,
        'File::Spec'    => 0,
        'perl'          => 5.008003,
        'Text::Diff'    => '0.35',
    },
    recommends => {
        'Test::Pod'           => '1.41',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Test-File-Contents/',
            bugtracker => 'https://github.com/theory/test-file-contents/issues/',
            repository => 'https://github.com/theory/test-file-contents',
        }
    },
    add_to_cleanup      => [ 'Test-File-Contents-*' ],
)->create_build_script;
