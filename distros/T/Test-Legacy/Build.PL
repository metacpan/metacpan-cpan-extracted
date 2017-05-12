#!/usr/bin/perl -w

use Module::Build;

my $mb = Module::Build->new(
  module_name   => 'Test::Legacy',
  license       => 'perl',
  requires      => {
                    perl                => '5.4.5',
                    Test::Builder       => '0.21_01',
                   },

  create_makefile_pl    => 'traditional'
);

$mb->create_build_script;



