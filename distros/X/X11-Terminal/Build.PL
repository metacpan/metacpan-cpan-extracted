#! /usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new (
     module_name => 'X11::Terminal',
     abstract_from => 'lib/X11/Terminal.pm',
     dist_author => 'Evan Giles <egiles@cpan.org>',
     license  => 'perl',
     requires => {
        'perl'            => '5.6.1',
        'Moose'           => 0.54,
     },
     create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => 0.38 },
     meta_merge     => {
         resources => {
             repository => "http://github.com/egiles/x11-terminal",
         },
     },
     add_to_cleanup => [ 'Makefile.PL', 'META.yml' ],
);
$build->create_build_script;
