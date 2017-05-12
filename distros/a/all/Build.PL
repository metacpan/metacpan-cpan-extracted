#!/usr/bin/perl

use Module::Build;

my $build = new Module::Build(
    module_name => 'all',
    license     => 'perl',
    requires    => {
        'perl'       => 5.006,
        'File::Spec' => 0,
        'File::Find' => 0,
    },
    create_makefile_pl => 'traditional',
    add_to_cleanup     => [
        'META.yml', '*.bak', '*.gz', '*.tgz', '*.ppd', '*.deb', '*.bat',
        'Makefile.PL', 'Makefile', 'pm_to_blib', 'cover_db',
        'all-*',
    ],
);

$build->create_build_script;
