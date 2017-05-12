#!/usr/bin/perl

# t/99min-perl.t
#  Tests that the minimum required Perl version matches META.yml
#
# $Id: 99min-perl.t 10597 2009-12-23 03:19:38Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More;

unless ($ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING}) {
  plan skip_all => 'Author tests not required for installation';
}

my %MODULES = (
  'Test::MinimumVersion'  => 0.008,
  'Perl::MinimumVersion'  => 1.20,
);

while (my ($module, $version) = each %MODULES) {
  eval "use $module $version";
  next unless $@;

  if ($ENV{RELEASE_TESTING}) {
    die 'Could not load release-testing module ' . $module;
  }
  else {
    plan skip_all => $module . ' not available for testing';
  }
}

all_minimum_version_from_metayml_ok();
