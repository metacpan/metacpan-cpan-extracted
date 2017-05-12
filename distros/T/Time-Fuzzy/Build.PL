#!perl
#
# This file is part of Time::Fuzzy.
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new (
    module_name         => 'Time::Fuzzy',
    dist_author         => 'Jerome Quelin <jquelin@cpan.org>',
    license             => 'perl',
    dist_version_from   => 'lib/Time/Fuzzy.pm',
    add_to_cleanup => [
        'Time-Fuzzy-*', 'MANIFEST.bak',
        map { ( '*/' x $_ ) . '*~' } 0..4 ],
    script_files   => [ ],
    build_requires => {
        'Class::Accessor' => 0,
        'DateTime'        => 0,
        'Test::More'      => 0,
    },
    requires       => { 
        'Class::Accessor' => 0,
        'DateTime'        => 0,
    },
    recommends     => {
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
    },
);

$builder->create_build_script();
