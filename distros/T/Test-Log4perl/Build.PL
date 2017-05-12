#!/usr/bin/perl
use Module::Build;

Module::Build->new(
  module_name   => 'Test::Log4perl',
  license       => 'perl',
  create_readme => 1,
  create_makefile_pl => 'traditional',
  requires      => {
    'Lingua::EN::Numbers::Ordinate' => 0,
    'Log::Log4perl'                 => 0,
    'Test::Builder'                 => 0,
    'Class::Accessor::Chained'      => 0,
    'Scalar::Util'                  => 0,
    'Carp'                          => 0,
  },
  build_requires => {
    'Test::Builder::Tester'         => "0.9",
    'Test::More'                    => 0,
    'Test::Exception'               => 0,
  },
)->create_build_script();
