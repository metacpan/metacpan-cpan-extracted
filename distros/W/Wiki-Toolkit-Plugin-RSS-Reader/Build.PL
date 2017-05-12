#!/usr/bin/perl

use strict;

use Module::Build;

Module::Build->new(
  module_name  => 'Wiki::Toolkit::Plugin::RSS::Reader',
  requires     => {
                    'LWP::Simple' => 0,
                    'XML::RSS'    => 0,
                  },
  license      => 'perl',
  sign => 1
)->create_build_script;
