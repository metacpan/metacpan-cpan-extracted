use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'URI::Nested',
    license            => 'perl',
    configure_requires => { 'Module::Build' => '0.30', },
    build_requires     => {
        'Module::Build' => '0.30',
        'Test::More'    => '0.88',
    },
    requires => {
        'perl' => 5.008001,
        'URI'  => '1.40',
    },
    meta_merge => {
        resources => {
            homepage   => 'https://metacpan.org/release/URI-Nested/',
            bugtracker => 'https://github.com/theory/uri-nested/issues/',
            repository => 'https://github.com/theory/uri-nested/',
        }
    },
)->create_build_script;
