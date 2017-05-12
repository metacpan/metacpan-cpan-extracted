#!/usr/bin/perl -w

use strict;

use Module::Build;

my $build = Module::Build->new
    ( module_name => 'Wx::Perl::EntryList',
      author      => 'Mattia Barbon <mbarbon@cpan.org>',
      license     => 'perl',
      requires    => { 'Wx'                    => 0.61,
                       'Class::Accessor'       => 0.27,
                       'Class::Publisher'      => 0.20,
                       'Wx::Perl::ListView'    => 0.01,
                       'Wx::Perl::ListCtrl'    => 0.02,
                       },
      build_requires => { 'Test::UseAllModules' => 0,
                          },
      create_makefile_pl => 'passthrough',
    );

$build->create_build_script;
