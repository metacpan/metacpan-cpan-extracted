#!/usr/bin/perl

use strict;

use lib 't';
use Test::Utils;
use Test::More;
use yagg::Config;
use File::Slurp;
use File::Spec::Functions qw( :ALL );

plan tests => 3;

chdir 't/logical_expressions_simple';

diag "Running \"make\" on some C++ code. Please be patient...";

my $testname = [splitdir($0)]->[-1];
$testname =~ s#\.t##;

my $test_stdout = catfile($TEMPDIR,"${testname}.stdout");
my $test_stderr = catfile($TEMPDIR,"${testname}.stderr");

#---------------------------------------------------------------------------

{
  system "$yagg::Config{'programs'}{'make'} clean 1>$test_stdout 2>$test_stderr";

  if ($?)
  {
    my $stdout = read_file($test_stdout);
    my $stderr = read_file($test_stderr);

    ok(0, "Encountered an error cleaning up.\nSTDOUT:\n$stdout\nSTDERR:\n$stderr\n");
  }
  else
  {
    ok(1, "Running make clean (first time)");
  }
}

#---------------------------------------------------------------------------

SKIP:
{
  skip("Make failed earlier",1) if $?;

  system "$yagg::Config{'programs'}{'make'} 1>$test_stdout 2>$test_stderr";

  if ($?)
  {
    my $stdout = read_file($test_stdout);
    my $stderr = read_file($test_stderr);

    ok(0, "Encountered an error building the sample code.\nSTDOUT:\n$stdout\nSTDERR:\n$stderr\n");
  }
  elsif (!-e 'progs/generate')
  {
    my $stdout = read_file($test_stdout);
    my $stderr = read_file($test_stderr);

    ok(0, "Build succeeded, but there is no \"progs/generate\".\nSTDOUT:\n$stdout\nSTDERR:\n$stderr\n");
  }
  else
  {
    ok(1, "Running make");
  }
}

#---------------------------------------------------------------------------

SKIP:
{
  skip("Make failed earlier",1) if $?;

  system "$yagg::Config{'programs'}{'make'} clean 1>$test_stdout 2>$test_stderr";

  if ($?)
  {
    my $stdout = read_file($test_stdout);
    my $stderr = read_file($test_stderr);

    ok(0, "Encountered an error cleaning up.\nSTDOUT:\n$stdout\nSTDERR:\n$stderr\n");
  }
  else
  {
    ok(1, "Running make clean");
  }
}
