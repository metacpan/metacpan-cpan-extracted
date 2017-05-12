#! /usr/bin/perl
#---------------------------------------------------------------------
# Build.PL for Texinfo-Menus
#
# Copyright 2010 Christopher J. Madsen
#---------------------------------------------------------------------

use strict;

use FindBin;
use lib $FindBin::Bin; # Make sure we're using My_Build from our distribution

use inc::My_Build;     # Our customized version of Module::Build

my %module_build_args = (
  module_name        => 'Texinfo::Menus',
  license            => 'perl',
  dist_author        => 'Christopher J. Madsen <perl@cjmweb.net>',
  dist_version_from  => 'lib/Texinfo/Menus.pm',
  dynamic_config     => 1,      # We have the --no-scripts option
  get_options        => { 'no-scripts' => undef },
  add_to_cleanup     => [ 't/testing' ],
  # Prerequisites inserted by DistZilla:
  'build_requires' => {
    'Module::Build' => '0.21'
  },
  'configure_requires' => {
    'Cwd' => '0',
    'File::Spec' => '0',
    'FindBin' => '0',
    'Module::Build' => '0.21',
    'perl' => '5.008'
  },
  'requires' => {
    'Exporter' => '0',
    'IO::File' => '0',
    'perl' => '5.008'
  },
  'test_requires' => {
    'Config' => '0',
    'FindBin' => '0',
    'Test::More' => '0.88'
  },
);

unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $builder = inc::My_Build->new(%module_build_args);

my @scripts;

if ($builder->args('no-scripts')) {
  $builder->dispatch('clean');   # The scripts might already be in blib/
} else {
  @scripts = qw(bin/up_menus);
}

$builder->script_files(\@scripts);

$builder->create_build_script;

unless (@scripts) {
  print "The up_menus script will not be installed (installing module only).\n";
} else {
  print "The up_menus script will be installed along with the module.\n";
  print "Run 'perl Build.PL --no-scripts' if you don't want this script installed.\n";
}
