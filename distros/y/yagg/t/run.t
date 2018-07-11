#!/usr/bin/perl

use strict;

use Test::More;
use lib 't';
use Test::Utils;
use File::Find;
use File::Path;
use File::Spec::Functions qw( :ALL );
use File::Slurper qw(read_text);

my %tests = (
  "yagg -r 2 -o $TEMPDIR/output t/grammars/infinite_loop.yg" =>
    ['infinite_loop','none'],
  "yagg -r 3 -o $TEMPDIR/output t/grammars/left_recursion.yg" =>
    ['left_recursion','none'],
);

my %expected_errors = (
);

plan tests => scalar (keys %tests) * 2;

diag "Generating, compiling, and running test generators. Please be patient...";

my %skip = SetSkip(\%tests);

foreach my $test (sort keys %tests) 
{
  print "Running test:\n  $test\n";

  SKIP:
  {
    skip("$skip{$test}",2) if exists $skip{$test};

    TestIt($test, $tests{$test}, $expected_errors{$test});
  }
}

# ---------------------------------------------------------------------------

sub TestIt
{
  my $test = shift;
  my ($stdout_file,$stderr_file) = @{ shift @_ };
  my $error_expected = shift;

  my $testname = [splitdir($0)]->[-1];
  $testname =~ s#\.t##;

  {
    my @standard_inc = split /###/, `$^X -e '\$" = "###";print "\@INC"'`;
    my @extra_inc;
    foreach my $inc (@INC)
    {
      push @extra_inc, "'$inc'" unless grep { $_ eq $inc } @standard_inc;
    }

    local $" = ' -I';
    if (@extra_inc)
    {
      $test =~ s#\byagg\s#$^X -I@extra_inc blib/script/yagg #g;
    }
    else
    {
      $test =~ s#\byagg\s#$^X blib/script/yagg #g;
    }
  }

  my $test_stdout = catfile($TEMPDIR,"${testname}_$stdout_file.stdout");
  my $test_stderr = catfile($TEMPDIR,"${testname}_$stderr_file.stderr");

  system "$test 1>$test_stdout 2>$test_stderr";

  if (!$? && defined $error_expected)
  {
    ok(0,"Did not encounter an error executing the test when one was expected.\n\n");

    SKIP: skip("Error running previous test",1);

    return;
  }

  if ($? && !defined $error_expected)
  {
    my $stdout = read_text($test_stdout, undef, 1);
    my $stderr = read_text($test_stderr, undef, 1);

    ok(0, "Encountered an error executing the test when one was not expected.\n" .
      "STDOUT:\n$stdout\nSTDERR:\n$stderr\n");

    SKIP: skip("Error running previous test",1);

    return;
  }

  my $real_stdout = catfile('t','results',$stdout_file);
  my $real_stderr = catfile('t','results',$stderr_file);

  Do_Diff($test_stdout,$real_stdout,$TEMPDIR);
  Do_Diff($test_stderr,$real_stderr,".*ranlib.*has no symbols\n");
}

# ---------------------------------------------------------------------------

sub SetSkip
{
  my %tests = %{ shift @_ };

  my %skip;

  return %skip;
}

# ---------------------------------------------------------------------------

