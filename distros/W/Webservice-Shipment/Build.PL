#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name        => 'Webservice::Shipment',
  dist_author        => 'Joel Berger <joel.a.berger@gmail.com>',
  license            => 'perl',
  configure_requires => { 'Module::Build' => 0.38 },
  requires => {
    'Mojolicious' => '5.0',
    'Time::Piece' => 0,
  },
  meta_merge => {
    resources => {
      repository => 'https://github.com/jberger/Webservice-Shipment',
      bugtracker => 'https://github.com/jberger/Webservice-Shipment/issues',
    },
  },
);

$build->create_build_script;
