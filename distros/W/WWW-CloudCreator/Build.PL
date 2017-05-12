#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::CloudCreator',
    license             => 'perl',
    dist_author         => 'Nick Gerakines <nick@socklabs.com>',
    dist_version_from   => 'lib/WWW/CloudCreator.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Differences' => 0,
        'POSIX' => 0,
    },
    add_to_cleanup      => [ 'WWW-CloudCreator-*' ],
);

$builder->create_build_script();
