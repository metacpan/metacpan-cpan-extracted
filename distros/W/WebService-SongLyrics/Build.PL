#!/usr/bin/perl -w
use strict;
use warnings;
use Module::Build;

Module::Build
  ->new( module_name => "WebService::SongLyrics",
         license     => 'perl',
         build_requires => {
             'Test::More' => 0,
         },
         requires => {
             'LWP::UserAgent' => 0,
             'URI::Escape'    => 0,
         },
   create_makefile_pl => 'traditional',
       )
  ->create_build_script;
