#! /usr/bin/perl -w
use strict;
use warnings;

use Test::More qw (no_plan);
use Data::Dumper;

use eBay::API::XML::Session;

# TODO: make this and other tests in this directory portable to Microsoft

$ENV{EBAY_LOG_LEVEL} = eBay::BaseApi::LOG_ERROR;
my $api = eBay::API::XML::Session->new();
my $rc = $api->testLogEntry("Testing testLogEntry().");
is($rc, 1, "Test testLogEntry().");
$rc = $api->logMessage(eBay::BaseApi::LOG_DEBUG, "This is debug message.\n");
is($rc, undef, "Debugging not logged at default log level.");
$rc = $api->logMessage(eBay::BaseApi::LOG_ERROR, "This is an error message.\n");
is($rc, 1, "Error messages logged at default log level.");

$ENV{EBAY_LOG_LEVEL} = eBay::BaseApi::LOG_DEBUG;
$api = eBay::API::XML::Session->new();
$rc = $api->logMessage(eBay::BaseApi::LOG_DEBUG, "This is debug message.\n");
is($rc, 1, "Debugging logged at debug log level.");
$rc = $api->logDebug("Another debug message.\n");
is($rc, 1, "Debugging logged at debug log level.");

$rc = $api->_logThis("Test using _logThis().\n",eBay::BaseApi::LOG_DEBUG);
is($rc, 1, "Test using _logThis().\n");

my $insubhandle = 0;

$api->setLogSubHandle(\&mylogger);
$rc = $api->logDebug("Test the logging subroutine handle.\n");
is($rc, 1, "Test the logging subroutine handle.\n");

is($insubhandle, 1, "Test the logging subroutine handle.\n");

# set up

my $session = eBay::API::XML::Session->new();
$api->setLogSubHandle(undef());
$session->setLogLevel(eBay::BaseApi::LOG_INFO);

# test logging to new file

open LOG, ">/tmp/test.log";
$session->setLogFileHandle(\*LOG);
$session->logInfo("Log info test.\n");
$session->dumpObject();
close(LOG);

$rc = system('grep "Log info test" /tmp/test.log');
is($rc, 0, "Found content in log file.");


# test the xml logger

my $goodxml = <<GOOD;
<XML><TAG1>This is tag one.</TAG1></XML>
GOOD

my $badxml = <<BAD;
<XML><TAG2>This is tag two with bad closing tag.<TAG2></XML>
BAD

open LOG, ">/tmp/test.log";
$session->setLogFileHandle(\*LOG);

$session->logXml(eBay::BaseApi::LOG_INFO, $goodxml);
close(LOG);
my $wc = `wc -l /tmp/test.log`;
$wc =~ s/^\s+//;
my ($count, $count1, $count2) = split(/\s+/, $wc);
is($count, 3, "Good xml was formatted.");
open LOG, ">>/tmp/test.log";
$session->logXml(eBay::BaseApi::LOG_INFO, $badxml);
$wc = `wc -l /tmp/test.log`;
$wc =~ s/^\s+//;
($count) = split(/\s+/, $wc);
is($count, 4, "Bad xml was not formatted.");
close(LOG);

# Test the header

$rc = system('grep "INFO" /tmp/test.log');
isnt($rc, 0, "Found NO header info in log file.");
open LOG, ">>/tmp/test.log";
$session->setLogHeader(1);
$rc = $api->logInfo("Test the logging header.\n");
close(LOG);
$rc = system('grep "INFO" /tmp/test.log');
is($rc, 0, "Found header info in log file.");

# tear down

unlink("/tmp/test.log");


sub mylogger {
  my $msg = shift;
  print "mylogger: " . $msg . "\n";
  $insubhandle = 1;
}
