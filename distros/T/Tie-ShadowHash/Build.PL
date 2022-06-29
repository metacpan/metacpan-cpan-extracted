#!/usr/bin/perl
#
# Build script for Tie::ShadowHash
#
# Copyright 1999, 2010, 2022 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

use 5.024;
use autodie;
use warnings;

use Module::Build;

# Basic package configuration.
#<<<
my $build = Module::Build->new(
    module_name          => 'Tie::ShadowHash',
    dist_author          => 'Russ Allbery <rra@cpan.org>',
    license              => 'perl',
    recursive_test_files => 1,
    add_to_cleanup       => [qw(MANIFEST.bak MYMETA.json.lock cover_db)],

    # Add additional package metadata.
    meta_merge => {
        'meta-spec' => { version => '2' },
        resources   => {
            bugtracker => {
                web => 'https://github.com/rra/shadowhash/issues',
            },
            homepage   => 'https://www.eyrie.org/~eagle/software/shadowhash',
            repository => {
                url  => 'https://github.com/rra/shadowhash.git',
                web  => 'https://github.com/rra/shadowhash',
                type => 'git',
            },
        },
    },

    # Other package relationships.
    configure_requires => { 'Module::Build' => 0.28 },
    requires           => { perl => '5.024' },
);
#>>>

# Generate the build script.
$build->create_build_script;
