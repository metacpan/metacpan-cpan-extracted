#! /usr/bin/perl
# payroll_test.pl - Tests the Business::Payroll module.
use strict;
use Business::Payroll;

my $file = "test.xml";

if (defined @ARGV[0])
{
  $file=@ARGV[0];
}

#  print "Using file: $file\n\n";
my $errStr = "(payroll_test) - Error:";

my $payrollObj = Business::Payroll->new();

my $dataObj = undef;

eval { $dataObj = $payrollObj->process(file => $file); };
#eval { $dataObj = $resultSetObj->parse(string => $xmlString); };
if ($@)
{
  die "$errStr  Eval failed: $@\n";
}

print $dataObj->generateXML;
