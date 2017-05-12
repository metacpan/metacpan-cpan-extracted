#!/usr/bin/perl

use strict;

use Module::Build;

Module::Build->new(
  module_name  => 'Wiki::Toolkit::Plugin::JSON',
  requires     => {
                    'JSON' => 0,
                    'Time::Piece' => 0,
                    'URI::Escape' => 0,
                  },
  recommends   => {
                    'Wiki::Toolkit' => 0,
                    'Test::JSON' => 0,
                  },
  license      => 'perl',
  sign => 1,
  dist_abstract => 'A Wiki::Toolkit plugin to output RecentChanges JSON.', 
)->create_build_script;
