#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Vim::Helper',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Exporter::Declare' => "0.105",
        'Declare::CLI'      => "0.007",
        'File::Temp'        => 0,
        'Carp'              => 0,
    },
    build_requires => {
        'Fennec'            => '1.012',
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Vim-Helper',
            bugtracker  => 'http://github.com/exodist/Vim-Helper',
        },
    },
    script_files => [ 'script/vimph' ],
);

$build->create_build_script;
