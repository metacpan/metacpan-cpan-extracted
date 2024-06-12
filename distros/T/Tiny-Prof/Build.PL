#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION( '0.4004' );

sub _readme {
    print "Building README\n";
    system "pod2markdown lib/Tiny/Prof.pm > README.md";
}
_readme();

my $builder = Module::Build->new(
    module_name        => 'Tiny::Prof',
    license            => 'artistic_2',
    dist_author        => q{tim Potapov <tim.potapov[AT]gmail.com>},
    dist_version_from  => 'lib/Tiny/Prof.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'perl' => '5.018',
    },
    add_to_cleanup => [
        'tiny-prof-*',
        'MANIFEST*.bak',
        'README*',
        'blib/',
    ],
    meta_merge     => {
        resources => {
            bugtracker => 'https://github.com/poti1/tiny-prof/issues',
            repository => 'https://github.com/poti1/tiny-prof',
        },
    },
);

$builder->create_build_script();
