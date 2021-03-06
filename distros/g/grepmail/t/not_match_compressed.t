#!/usr/bin/perl

use strict;

use Test::More;
use lib 't';
use Test::Utils;
use File::Spec::Functions qw( :ALL );

my %tests = (
'grepmail -v Handy t/mailboxes/mailarc-1.txt.gz'
  => ['not_handy','none'],
'grepmail -v Handy t/mailboxes/mailarc-1.txt.bz2'
  => ['not_handy','none'],
'grepmail -v Handy t/mailboxes/mailarc-1.txt.lz'
  => ['not_handy','none'],
'grepmail -v Handy t/mailboxes/mailarc-1.txt.xz'
  => ['not_handy','none'],
"grepmail -v -E $single_quote\$email =~ /Handy/$single_quote t/mailboxes/mailarc-1.txt.gz"
  => ['not_handy','none'],
"grepmail -v -E $single_quote\$email =~ /Handy/$single_quote t/mailboxes/mailarc-1.txt.bz2"
  => ['not_handy','none'],
"grepmail -v -E $single_quote\$email =~ /Handy/$single_quote t/mailboxes/mailarc-1.txt.lz"
  => ['not_handy','none'],
"grepmail -v -E $single_quote\$email =~ /Handy/$single_quote t/mailboxes/mailarc-1.txt.xz"
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
    $skip{'grepmail -v Handy t/mailboxes/mailarc-1.txt.gz'}
      = 'gzip support not enabled in Mail::Mbox::MessageParser';
    $skip{"grepmail -v -E $single_quote\$email =~ /Handy/$single_quote t/mailboxes/mailarc-1.txt.gz"}
      = 'gzip support not enabled in Mail::Mbox::MessageParser';
  }

  unless (defined $Mail::Mbox::MessageParser::Config{'programs'}{'bzip2'})
  {
    $skip{'grepmail -v Handy t/mailboxes/mailarc-1.txt.bz2'}
      = 'bzip2 support not enabled in Mail::Mbox::MessageParser';
    $skip{"grepmail -v -E $single_quote\$email =~ /Handy/$single_quote t/mailboxes/mailarc-1.txt.bz2"}
      = 'bzip2 support not enabled in Mail::Mbox::MessageParser';
  }

  unless (defined $Mail::Mbox::MessageParser::Config{'programs'}{'lzip'})
  {
    $skip{'grepmail -v Handy t/mailboxes/mailarc-1.txt.lz'}
      = 'lzip support not enabled in Mail::Mbox::MessageParser';
    $skip{"grepmail -v -E $single_quote\$email =~ /Handy/$single_quote t/mailboxes/mailarc-1.txt.lz"}
      = 'lzip support not enabled in Mail::Mbox::MessageParser';
  }

  unless (defined $Mail::Mbox::MessageParser::Config{'programs'}{'xz'})
  {
    $skip{'grepmail -v Handy t/mailboxes/mailarc-1.txt.xz'}
      = 'xz support not enabled in Mail::Mbox::MessageParser';
    $skip{"grepmail -v -E $single_quote\$email =~ /Handy/$single_quote t/mailboxes/mailarc-1.txt.xz"}
      = 'xz support not enabled in Mail::Mbox::MessageParser';
  }

  return %skip;
}

# ---------------------------------------------------------------------------

