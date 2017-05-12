#!/usr/bin/perl -w
use strict;
use warnings;

use Module::Build;

Module::Build
  ->new( module_name => "WebService::BBC::MusicCharts",
         license     => 'perl',
         build_requires => {
             'Test::More' => 0,
         },
         requires => {
             'LWP::Simple'       => 0,
             'Template::Extract' => 0,
         },
   create_makefile_pl => 'traditional',
       )
  ->create_build_script;
