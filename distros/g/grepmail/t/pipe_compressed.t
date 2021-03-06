#!/usr/bin/perl

use strict;

use Test::More;
use lib 't';
use Test::Utils;
use File::Spec::Functions qw( :ALL );

my $CAT = perl_with_inc() . qq{ -MTest::Utils -e catbin};

my %tests = (
"$CAT t/mailboxes/mailarc-1.txt.gz | grepmail Handy"
  => ['all_handy','none'],
"$CAT t/mailboxes/mailarc-1.txt.bz2 | grepmail Handy"
  => ['all_handy','none'],
"$CAT t/mailboxes/mailarc-1.txt.lz | grepmail Handy"
  => ['all_handy','none'],
"$CAT t/mailboxes/mailarc-1.txt.xz | grepmail Handy"
  => ['all_handy','none'],
"$CAT t/mailboxes/mailarc-1.txt.gz | grepmail -v -E $single_quote\$email =~ /Handy/$single_quote"
  => ['not_handy','none'],
"$CAT t/mailboxes/mailarc-1.txt.bz2 | grepmail -v -E $single_quote\$email =~ /Handy/$single_quote"
  => ['not_handy','none'],
"$CAT t/mailboxes/mailarc-1.txt.lz | grepmail -v -E $single_quote\$email =~ /Handy/$single_quote"
  => ['not_handy','none'],
"$CAT t/mailboxes/mailarc-1.txt.xz | grepmail -v -E $single_quote\$email =~ /Handy/$single_quote"
  => ['not_handy','none'],
);

my %expected_errors = (
);

plan tests => scalar (keys %tests) * 2;

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

  my $perl = perl_with_inc();

  $test =~ s#\bgrepmail\s#$perl blib/script/grepmail -C $TEMPDIR/cache #g;

  my $test_stdout = catfile($TEMPDIR,"${testname}_$stdout_file.stdout");
  my $test_stderr = catfile($TEMPDIR,"${testname}_$stderr_file.stderr");

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

  my $real_stdout = catfile('t','results',$stdout_file);
  my $real_stderr = catfile('t','results',$stderr_file);

  # Compare STDERR first on the assumption that if STDOUT is different, STDERR
  # is too and contains something useful.
  Do_Diff($test_stderr,$real_stderr);
  Do_Diff($test_stdout,$real_stdout);
}

# ---------------------------------------------------------------------------

sub SetSkip
{
  my %tests = %{ shift @_ };

  my %skip;

  unless (defined $Mail::Mbox::MessageParser::Config{'programs'}{'gzip'})
  {
    $skip{"$CAT t/mailboxes/mailarc-1.txt.gz | grepmail Handy"}
      = 'gzip support not enabled in Mail::Mbox::MessageParser';
    $skip{"$CAT t/mailboxes/mailarc-1.txt.gz | grepmail -v -E $single_quote\$email =~ /Handy/$single_quote"}
      = 'gzip support not enabled in Mail::Mbox::MessageParser';
  }

  unless (defined $Mail::Mbox::MessageParser::Config{'programs'}{'bzip2'})
  {
    $skip{"$CAT t/mailboxes/mailarc-1.txt.bz2 | grepmail Handy"}
      = 'bzip2 support not enabled in Mail::Mbox::MessageParser';
    $skip{"$CAT t/mailboxes/mailarc-1.txt.bz2 | grepmail -v -E $single_quote\$email =~ /Handy/$single_quote"}
      = 'bzip2 support not enabled in Mail::Mbox::MessageParser';
  }

  unless (defined $Mail::Mbox::MessageParser::Config{'programs'}{'lzip'})
  {
    $skip{"$CAT t/mailboxes/mailarc-1.txt.lz | grepmail Handy"}
      = 'lzip support not enabled in Mail::Mbox::MessageParser';
    $skip{"$CAT t/mailboxes/mailarc-1.txt.lz | grepmail -v -E $single_quote\$email =~ /Handy/$single_quote"}
      = 'lzip support not enabled in Mail::Mbox::MessageParser';
  }

  unless (defined $Mail::Mbox::MessageParser::Config{'programs'}{'xz'})
  {
    $skip{"$CAT t/mailboxes/mailarc-1.txt.xz | grepmail Handy"}
      = 'xz support not enabled in Mail::Mbox::MessageParser';
    $skip{"$CAT t/mailboxes/mailarc-1.txt.xz | grepmail -v -E $single_quote\$email =~ /Handy/$single_quote"}
      = 'xz support not enabled in Mail::Mbox::MessageParser';
  }

  return %skip;
}
