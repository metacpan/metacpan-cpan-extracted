#!/usr/bin/perl -w

use 5.008001;

use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'YYZ',
    license     => 'perl',

    dist_author => 'Michael G Schwern <schwern@pobox.com>',

    meta_merge  => {
        resources => {
            bugtracker =>
              'http://rt.cpan.org/Public/Dist/Display.html?Name=YYZ',
            repository =>
              'http://github.com/schwern/YYZ/tree/master',
        },

        keywords => [ 'Rush', 'XXX' ],

        configure_requires => {
            'Module::Build'     => 0.2808
        },
    },

    build_requires      => {
        'Test::More'        => 0.88,
    },

    requires             => {
        XXX                 => '0.17',
        perl                => '5.8.1',
    },
);

$builder->create_build_script();
