#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'constant::tiny',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/constant/tiny.pm',
    requires => {
    },
    build_requires => {
        'Test::More'        => 0,
    },
    configure_requires => {
        'Module::Build'     => 0.38,
    },
    meta_merge => {
        resources       => {
            repository  => "https://github.com/maddingue/constant-tiny",
            #{
            #    type    => "git",
            #    url     => "git://github.com/maddingue/constant-tiny.git",
            #    web     => "https://github.com/maddingue/constant-tiny",
            #}
        },
    },
    add_to_cleanup      => [ 'constant-tiny-*' ],
);

$builder->create_build_script();
