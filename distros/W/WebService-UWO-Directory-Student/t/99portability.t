#!/usr/bin/perl -T

# t/99portability.t
#  Tests if the distribution seems to be portable
#
# $Id: 99portability.t 10597 2009-12-23 03:19:38Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More;

unless ($ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING}) {
  plan skip_all => 'Author tests not required for installation';
}

my %MODULES = (
  'Test::Portability::Files' => 0,
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

options(
  # For descriptions of what these do, consult Test::Portability::Files
  test_amiga_length   => 1,
  test_ansi_chars     => 1,
  test_case           => 1,
  test_dir_noext      => 1,
  test_dos_length     => 0,
  test_mac_length     => 1,
  test_one_dot        => 0,
  test_space          => 1,
  test_special_chars  => 1,
  test_symlink        => 1,
  test_vms_length     => 1,
  use_file_find       => 0,
);

run_tests();
