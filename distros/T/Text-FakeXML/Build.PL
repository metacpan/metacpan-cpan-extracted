#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::FakeXML',
    license             => 'perl',
    dist_author         => 'Johan Vromans <jv@cpan.org>',
    dist_version_from   => 'lib/Text/FakeXML.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Text-FakeXML-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
