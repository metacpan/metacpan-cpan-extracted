#!perl

use 5.006;
use strict;
use warnings;

# Automatically generated file; DO NOT EDIT.

use Test::More;

use lib qw(lib);

my @modules = qw(
  Test::RequiredMinimumDependencyVersion
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}
