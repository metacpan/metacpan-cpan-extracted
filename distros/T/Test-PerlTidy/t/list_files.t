#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

use Test::PerlTidy ();

my @wanted_files = sort qw(
  Build.PL
  Makefile.PL
  lib/Test/PerlTidy.pm
  t/00-compile.t
  t/critic.t
  t/exclude_files.t
  t/exclude_perltidy.t
  t/is_file_tidy.t
  t/list_files.t
  t/perltidy.t
);

@wanted_files = map { my $ret = $_; $ret =~ s/\//\\/g; $ret } @wanted_files
  if $^O eq 'MSWin32';

my @found_files =
  Test::PerlTidy::list_files( path => '.', exclude => [ qr/blib|xt/, ], );

# TEST
is_deeply( \@wanted_files, \@found_files );
