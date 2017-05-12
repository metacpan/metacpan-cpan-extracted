#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'sqlfs-perl',
    license           => 'perl',
    dist_version_from => 'lib/DBI/Filesystem.pm',
    dist_abstract     => 'Store a filesystem in a relational database',
    dist_author       => 'Lincoln Stein <lincoln.stein@oicr.on.ca>',
    configure_requires => { 'Module::Build' => 0 },
    requires          => {
      'Fuse'          => '0.15',
      'DBI'           => 0,
      'threads'       => 0,
    },
    build_class        => 'Module::Build',
    );

$build->create_build_script;
exit 0;
