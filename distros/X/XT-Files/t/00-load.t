#!perl

use 5.006;
use strict;
use warnings;

# Automatically generated file; DO NOT EDIT.

use Test::More 0.88;

use lib qw(lib);

my @modules = qw(
  Test::XTFiles
  XT::Files
  XT::Files::File
  XT::Files::Plugin
  XT::Files::Plugin::Default
  XT::Files::Plugin::Dirs
  XT::Files::Plugin::Excludes
  XT::Files::Plugin::Files
  XT::Files::Plugin::lib
  XT::Files::Role::Logger
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}
