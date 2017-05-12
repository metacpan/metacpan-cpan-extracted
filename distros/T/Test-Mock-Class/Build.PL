#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use Module::Build;

my $module = 'Test::Mock::Class';

(my $dist = $module) =~ s/::/-/g;

my $build = Module::Build->new(
    module_name => $module,
    license => 'lgpl',
    requires => {
        'perl'               => 5.006,
        'namespace::clean'   => 0,
        'Class::MOP'         => 0.93,
        'Exception::Base'    => 0,
        'Exception::Fatal'   => 0,
        'Moose'              => 0.90,
        'Test::Assert'       => 0.05,
    },
    optional => {
    },
    build_requires => {
        'Class::Inspector'   => 0,
        'Test::Unit::Lite'   => 0.12,
    },
    auto_configure_requires => 0,
    create_makefile_pl => 'traditional',
    create_readme => 1,
    create_license => 1,
    sign => 1,
    recursive_test_files => 1,
    add_to_cleanup => [
        '*.bak', '*.gz', '*.tgz', '*.ppd', '*.ppmx', '*.deb', '*.bat',
        'Makefile', 'pm_to_blib', 'cover_db', 'xt/Debian_CPANTS.txt',
        "$dist-*",
    ],
    meta_merge => {
        resources => {
            bugtracker => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=$dist",
            repository => "http://github.com/dex4er/$dist",
        },
    },
);

$build->create_build_script;
