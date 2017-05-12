#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

use Test::PerlTidy;

my @wanted_files = sort qw(
  Makefile.PL
  lib/Test/PerlTidy.pm
  t/critic.t
  t/exclude_files.t
  t/exclude_perltidy.t
  t/is_file_tidy.t
  t/list_files.t
  t/perltidy.t
  t/pod-coverage.t
  t/pod.t
  t/strict.t
);

my @found_files = Test::PerlTidy::list_files('.');

is_deeply( \@wanted_files, \@found_files );
