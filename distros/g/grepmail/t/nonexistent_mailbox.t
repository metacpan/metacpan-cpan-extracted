#!/usr/bin/perl

use strict;

use Test::More;
use lib 't';
use Test::Utils;
use File::Spec::Functions qw( :ALL );
use File::Copy;
use File::Slurper qw(read_binary write_binary);

my %tests = (
'grepmail pattern no_such_file'
  => ['none','no_such_file'],
"grepmail -E $single_quote\$email =~ /pattern/$single_quote no_such_file"
  => ['none','no_such_file'],
);

my %expected_errors = (
);

my %localization = (
  "grepmail -E $single_quote\$email =~ /pattern/$single_quote no_such_file" =>
    { 'stderr' => { 'search' => '[No such file or directory]',
      'replace' => No_such_file_or_directory() },
    },
  'grepmail pattern no_such_file' =>
    { 'stderr' => { 'search' => '[No such file or directory]',
      'replace' => No_such_file_or_directory() },
    },
);

plan tests => scalar (keys %tests) * 2;

my %skip = SetSkip(\%tests);

foreach my $test (sort keys %tests) 
{
  print "Running test:\n  $test\n";

  SKIP:
  {
    skip("$skip{$test}",2) if exists $skip{$test};

    TestIt($test, $tests{$test}, $expected_errors{$test}, $localization{$test});
  }
}

# ---------------------------------------------------------------------------

sub TestIt
{
  my $test = shift;
  my ($stdout_file,$stderr_file) = @{ shift @_ };
  my $error_expected = shift;
  my $localization = shift;

  my $testname = [splitdir($0)]->[-1];
  $testname =~ s#\.t##;

  my $perl = perl_with_inc();

  $test =~ s#\bgrepmail\s#$perl blib/script/grepmail -C $TEMPDIR/cache #g;

  my $test_stdout = catfile($TEMPDIR,"${testname}_$stdout_file.stdout");
  my $test_stderr = catfile($TEMPDIR,"${testname}_$stderr_file.stderr");

  print "$test 1>$test_stdout 2>$test_stderr\n";
  system "$test 1>$test_stdout 2>$test_stderr";

  if (!$? && defined $error_expected)
  {
    ok(0,"Did not encounter an error executing the test when one was expected.\n\n");
    return;
  }

  if ($? && !defined $error_expected)
  {
    ok(0, "Encountered an error executing the test when one was not expected.\n" .
      "See $test_stdout and $test_stderr.\n\n");
    return;
  }

  my $modified_stdout = "$TEMPDIR/$stdout_file";
  my $modified_stderr = "$TEMPDIR/$stderr_file";

  my $real_stdout = catfile('t','results',$stdout_file);
  my $real_stderr = catfile('t','results',$stderr_file);

  if (defined $localization->{'stdout'})
  {
    LocalizeTestOutput($localization->{'stdout'}, $real_stdout, $modified_stdout);
  }
  else
  {
    copy($real_stdout, $modified_stdout);
  }

  if (defined $localization->{'stderr'})
  {
    LocalizeTestOutput($localization->{'stderr'}, $real_stderr, $modified_stderr)
  }
  else
  {
    copy($real_stderr, $modified_stderr);
  }

  # Compare STDERR first on the assumption that if STDOUT is different, STDERR
  # is too and contains something useful.
  Do_Diff($test_stderr,$modified_stderr);
  Do_Diff($test_stdout,$modified_stdout);

  unlink $modified_stdout;
  unlink $modified_stderr;
}

# ---------------------------------------------------------------------------

sub SetSkip
{
  my %tests = %{ shift @_ };

  my %skip;

  return %skip;
}

# ---------------------------------------------------------------------------

sub LocalizeTestOutput
{
  my $search_replace = shift;
  my $original_file = shift;
  my $new_file = shift;

  my $original = read_binary($original_file);

  my $new = $original;
  $new =~ s/\Q$search_replace->{'search'}\E/$search_replace->{'replace'}/gx;

  write_binary($new_file, $new);
}

# ---------------------------------------------------------------------------

