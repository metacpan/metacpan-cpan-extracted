#!/usr/bin/perl -w

use strict;
use lib 'inc';
use MyBuild;

my $builder = MyBuild->new(
    module_name => 'Test::Sims',
    license     => 'perl',
    dist_author => 'Michael G Schwern <schwern@pobox.com>',

    requires           => { 'perl'          => '5.8.1', },
    build_requires     => { 'Test::More'    => '0.88', },
    configure_requires => { 'Module::Build' => '0.32' },

    meta_merge => {
        resources => {
            homepage   => 'http://github.com/schwern/Test-Sims',
            repository => 'http://github.com/schwern/Test-Sims/tree/master',
            bugtracker => 'http://github.com/schwern/Test-Sims/issues',
        },
    },

    recursive_test_files => 1,
);

$builder->create_build_script();
