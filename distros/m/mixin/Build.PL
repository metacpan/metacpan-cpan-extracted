#!/usr/bin/perl

use warnings;
use strict;

use Module::Build;

my $build = Module::Build->new(
    module_name         => "mixin",
    license             => "perl",

    recursive_test_files => 1,

    configure_requires => {
        "Module::Build" => '0.36'
    },
    
    requires            => {
        "base"                  => 0,
    },
    build_requires      => {
        "Test::More"            => 0.40,
        "Test::NoWarnings"      => 0,
    },

    create_readme       => 1,
    create_license      => 1,

    meta_merge          => {
        resources       => {
            homepage    => "https://github.com/evalEmpire/mixin",
            bugtracker  => "https://github.com/evalEmpire/mixin/issues",
            repository  => "https://github.com/evalEmpire/mixin",
        },
        keywords        => [qw(mixin inheritance devel)],
    }
);
$build->create_build_script;
