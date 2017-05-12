#!perl -w
use strict;
use Module::Build;

Module::Build
  ->new( module_name => "WWW::Shorten::Smallr",
         license     => 'perl',
         build_requires => {
             'Test::More' => 0,
         },
         requires => {
             'WWW::Shorten' => 0,
             'Carp' => 0,
         },
   create_makefile_pl => 'traditional',
       )
  ->create_build_script;
