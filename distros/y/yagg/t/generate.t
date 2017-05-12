#!/usr/bin/perl

use strict;

use lib 't';
use Test::Utils;
use Test::More;
use File::Find;
use File::Spec::Functions qw( :ALL );
use File::Slurp;

my @tests = (
  "yagg -f -o $TEMPDIR/output examples/logical_expressions_simple/logical_expression.yg examples/logical_expressions_simple/logical_expression.lg",
);

my %expected_errors = (
);

plan tests => scalar @tests;

foreach my $test (@tests) 
{
  print "Running test:\n  $test\n";

  TestIt($test);
}

# ---------------------------------------------------------------------------

sub TestIt
{
  my $test = shift;

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

  my $test_stdout = catfile($TEMPDIR,"${testname}.stdout");
  my $test_stderr = catfile($TEMPDIR,"${testname}.stderr");

  system "$test 1>$test_stdout 2>$test_stderr";

  if ($?)
  {
    my $stdout = read_file($test_stdout);
    my $stderr = read_file($test_stderr);

    ok(0, "Encountered an error executing the test.\nSTDOUT:\n$stdout\nSTDERR:\n$stderr\n");
  }
  else
  {
    my $generated = '';
    my $actual = '';
    find(sub
         {
           $generated .= "$File::Find::name\n"
             unless $File::Find::name =~ /\b(CVS|build|lib|tests|progs)\b/
         }, "$TEMPDIR/output");
    find(sub
         { $actual .= "$File::Find::name\n"
             unless $File::Find::name =~ /\b(CVS|build|lib|tests|progs)\b/
         }, 't/logical_expressions_simple');

    $actual =~ s#t/logical_expressions_simple#$TEMPDIR/output#g;

    my @actual = $actual =~ /^(.*\n)/mg;
    my @generated = $generated =~ /^(.*\n)/mg;

    @actual = grep { !/(\.std(out|err)|\.svn)/ } @actual;

    @actual = sort @actual;
    @generated = sort @generated;

    is_deeply(\@generated, \@actual,
      "Comparing files generated for logical_expressions_simple,\n" .
      " in $TEMPDIR/output/ and t/logical_expressions_simple\n");
  }
}
