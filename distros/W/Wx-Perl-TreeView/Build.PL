#!/usr/bin/perl -w

use Module::Build;

Module::Build->new
  ( module_name => 'Wx::Perl::TreeView',
    author      => 'Mattia Barbon <mbarbon@cpan.org>',
    license     => 'perl',
    requires    => { 'Wx'         => 0.26,
                     'Test::More' => 0.50,
                     },
    create_makefile_pl => 'passthrough',
)->create_build_script;
