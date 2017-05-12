#!/usr/bin/perl -w

use Module::Build 0.30;

require 5.006;

my $build = Module::Build->new(
    module_name         => 'URI::Find',

    configure_requires  => {
        Module::Build   => '0.30'
    },

    build_requires      => {
        Test::More      => '0.88',
        Module::Build   => '0.30',
    },

    requires            => {
        perl            => '5.8.8',
        URI             => '1.60',
    },

    license             => 'perl',

    dist_author => 'Michael G Schwern <schwern@pobox.com>',

    meta_merge => {
        resources => {
            homepage        => 'http://metacpan.org/release/URI-Find',
            bugtracker      => 'http://github.com/schwern/URI-Find/issues/',
            repository      => 'http://github.com/schwern/URI-Find/',
        }
    },

    recursive_test_files        => 1,

    create_readme               => 1,
    create_license              => 1,
);

$build->create_build_script;
