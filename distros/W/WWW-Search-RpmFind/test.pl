# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

# 6 tests without "goto MULTI_RESULT"
BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1 Load test\n" unless $loaded;}
use WWW::Search::RpmFind;
$loaded = 1;
print "ok 1 - Load test\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $tt = 6;
my $ok = 1;
my $iTest = 2;

my $sEngine = 'RpmFind';
my $oSearch = new WWW::Search($sEngine);
if (ref($oSearch)) { $ok++; }
print  ref($oSearch) ? '' : 'not ';
print "ok $iTest - WWW::Search compliant - wait 5 s\n";
sleep(5);

use WWW::Search::Test;
$oSearch->{_debug}=0;

# This test returns no results (but we should not get an HTTP error):
$iTest++;
$oSearch->native_query($WWW::Search::Test::bogus_query);
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
$ok++ if (0 == $iResults);
print STDOUT (0 < $iResults) ? 'not ' : '';
print "ok $iTest - bogus query - wait 5 s\n";
sleep(5);

# goto MULTI_RESULT;

# This query returns 1 page of results:
$iTest++;
my $sQuery = 'libmpeg3';
$oSearch->native_query(WWW::Search::escape_query($sQuery),
                         { 'search_debug' => $debug, },
                      );
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
if (($iResults < 2) || (49 < $iResults)) {
  print STDERR " --- got $iResults results for $sQuery, but expected 2..49\n";
  print STDOUT 'not ';
}
else { $ok++; }
print "ok $iTest - query on libmpeg3 2<x<50 - wait 5 s\n";
sleep(5);

# This query returns 2 pages of results:
$iTest++;
$sQuery = 'libmpeg';
$oSearch->native_query(WWW::Search::escape_query($sQuery),
                         { 'search_debug' => $debug, },
                      );
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
if (($iResults < 51) || (99 < $iResults))  {
  print STDERR " --- got $iResults results for $sQuery, but expected 51..99\n";
  print STDOUT 'not ';
}
else { $ok++; }
print "ok $iTest - query on libmpeg 50<x<100 - wait 5 s\n";
sleep(5);

ULTI_RESULT:
# $debug = 1;

# This query returns 3 pages of results:
$iTest++;
$sQuery = 'cvs';
$oSearch->native_query($sQuery, { 'search_debug' => $debug, });
$oSearch->maximum_to_retrieve(120);
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
if ($iResults < 101)
  {
  print STDERR " --- got $iResults results for $sQuery, but expected > 101\n";
  print STDOUT 'not ';
  }
else { $ok++; }
print "ok $iTest - query on cvs x<100\n";

($tt == $ok) ? exit(0) : exit(-1);
