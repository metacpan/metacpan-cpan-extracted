#!/usr/bin/perl -w
#

#########################################################################
#
# Module: ............... testSuite.t
# File: ................. testSuite.t
# Original Author: ...... Bob Bradley
# Last Modified By: ..... 
# Last Modified: ........ 
#
#
#########################################################################


=pod

=head1 testSuite.t


Runs tests in install and sandbox directories.

Usage:

    testSuite.t --mode=[install|sandbox|all]

    where

      install = run installation tests
      sandbox = run test calls against the API
      all = run both kinds of tests

Only test scripts with an extension of '.t' will be run.  This means
you can put readme files and supporting modules in the install and
sandbox directories.

To run the sandbox tests you must have api certification and valid
user credentials, and have those defined in their respective environment
variables.  See API documentation for more details.

Results of the tests will go to STDOUT.  If any failures
were encountered they will be reported as they are encountered,
and again in summary form at the end of the test run.

This script also exits with a status of 0 on success, or > 0 when
tests failed.  In the case of failures, the status code returned will
be the number of tests that failed.

=cut


use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use File::Basename;

my $mode  = '';
my @files = ();
my ($self, $path, $suffix) = fileparse($0);

GetOptions (  'mode=s' => \$mode);
usage ($mode, $self);
if ($mode eq 'install') {
  @files = glob($path . "install/*.t");
}
if ($mode eq 'sandbox') {
  @files = glob($path . "sandbox/*.t");
}
if ($mode eq 'all') {
  @files = glob($path . "install/*.t");
  push @files, glob($path . "sandbox/*.t");
}

my @failedtests = ();
foreach (@files) {
  if (system("perl -w $_") > 0 ) {
    print "\===================\n". $_ . " FAILED!\n===================\n";
    push @failedtests, $_;
  }
}

if (scalar @failedtests) {
    print "\n===================\nSome tests FAILED!\n===================\n";
    foreach (@failedtests) {
      print "\t$_\n";
    }
} else {
  print "\n===================\nAll tests passed!\n===================\n";
}

exit scalar @failedtests;

sub usage {
  my $mode = shift;
  my $self = shift;
  if ($mode eq 'all' or $mode eq 'install' or $mode eq 'sandbox') {
    return;
  }
  my $msg = <<"USAGE";

usage:

    $self --mode=[install|sandbox|all]

    where

      install = run installation tests
      sandbox = run test calls against the API
      all = run both kinds of tests

To run the sandbox tests you must have api certification and valid
user credentials, and have those defined in their respective environment
variables.  See API documentation for more details.

USAGE
    print $msg;
    exit;
}




