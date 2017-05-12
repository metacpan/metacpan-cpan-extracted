#! /usr/bin/perl
#---------------------------------------------------------------------
# Build.PL for WebService-NFSN
#
# Copyright 2010 Christopher J. Madsen
#---------------------------------------------------------------------

use strict;
use warnings;

use inc::My_Build;           # Our customized version of Module::Build

my $builder = inc::My_Build->new(
  module_name        => 'WebService::NFSN',
  license            => 'perl',
  dist_author        => 'Christopher J. Madsen <perl@cjmweb.net>',
  dist_version_from  => 'lib/WebService/NFSN.pm',
  dynamic_config     => 0,
  # Automatically inserted by DistZilla:
  'build_requires' => {
    'FindBin' => '0',
    'Module::Build' => '0.36',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.36',
    'parent' => '0'
  },
  'recommends' => {
    'Data::Dumper' => '0'
  },
  'requires' => {
    'Carp' => '0',
    'Digest::SHA' => '0',
    'Exception::Class' => '0',
    'Exporter' => '5.57',
    'File::Spec' => '0',
    'HTTP::Request::Common' => '0',
    'JSON::XS' => '1',
    'LWP::Protocol::https' => '6',
    'LWP::UserAgent' => '6',
    'Scalar::Util' => '1.01',
    'Try::Tiny' => '0.04',
    'URI' => '1.00',
    'parent' => '0',
    'perl' => '5.006'
  },
);

$builder->create_build_script();
