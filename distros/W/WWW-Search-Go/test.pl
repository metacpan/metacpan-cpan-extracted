# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;
use WWW::Search::Test;

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

# 6 tests 
BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use WWW::Search::Go;
$loaded = 1;
print "ok 1 Load test\n";

######################### End of black magic.

my $tt = 6;
my $ok = 1;
my $iTest = 2;

my $sEngine = 'Go';
my $oSearch = new WWW::Search($sEngine);
print ref($oSearch) ? '' : 'not ';
print "ok $iTest WWW::Search compliant\n";
$ok++ if (ref($oSearch));

my $debug = 0;

# This test returns no results (but we should not get an HTTP error):
$iTest++;
$oSearch->native_query($WWW::Search::Test::bogus_query);
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
print STDOUT (0 < $iResults) ? 'not ' : '';
print "ok $iTest Bogus query\n";
$ok++ if ($iResults==0);
sleep(2);

# This query returns 1 page of results:
$iTest++;
my $sQuery = '+LS'.'AM +replic'.'ation';
$oSearch->native_query(WWW::Search::escape_query($sQuery),
                         { 'search_debug' => $debug, },
                      );
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
if (($iResults < 2) || (49 < $iResults))
  {
  print STDERR " --- got $iResults results for $sQuery, but expected 2..49\n";
  print STDOUT 'not ';
  }
else { $ok++; }
print "ok $iTest Query $sQuery results 2<x<50\n";

sleep(2);

# This query returns 2 pages of results:
$iTest++;
$sQuery = 'alien';
$oSearch->native_query(WWW::Search::escape_query($sQuery),
                         { 'search_debug' => $debug, },
                      );
@aoResults = $oSearch->results();
$oSearch->maximum_to_retrieve(120);
$iResults = scalar(@aoResults);
if (($iResults < 51) || (99 < $iResults))
  {
  print STDERR " --- got $iResults results for $sQuery, but expected 51..99\n";
  print STDOUT 'not ';
  }
else { $ok++; }
print "ok $iTest Query $sQuery results 50<x<100\n";
sleep(2);

# This query returns 3 pages of results:
$iTest++;
$sQuery = 'internet';
$oSearch->native_query($sQuery,
                         { 'search_debug' => $debug, },
                      );
$oSearch->maximum_to_retrieve(120);
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
if ($iResults < 101)
  {
  print STDERR " --- got $iResults results for $sQuery, but expected > 101\n";
  print STDOUT 'not ';
  }
else { $ok++; }
print "ok $iTest Query $sQuery results x>100\n";

# Code sortie final
my $ex = 0;
if ($tt != $ok) { $ex=-1; print "Some tests fails\n"; }
else { print "All tests successful\n"; }
exit($ex);
