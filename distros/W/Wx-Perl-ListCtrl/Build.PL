#!/usr/bin/perl -w

use Module::Build;

Module::Build->new
  ( module_name => 'Wx::Perl::ListCtrl',
    license     => 'perl',
    requires    => { 'Wx'           => '0.20',
                     'Test::More'   => '0.50',
                     },
   )->create_build_script;
