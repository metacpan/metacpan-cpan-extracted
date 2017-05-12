# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

# 6 tests without "goto MULTI_RESULT"
BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1 use test\n" unless $loaded;}
use WWW::Search::Nomade;
$loaded = 1;

print "ok 1 use test\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $iTest = 2;
my $ok = 7;
my $tt = 1;
my $sEngine = 'Nomade';
my $oSearch = new WWW::Search($sEngine);
print ref($oSearch) ? '' : 'not ';
print "ok $iTest WWW::Search compliant\n";
$tt++ if (ref($oSearch));
use WWW::Search::Test;
$oSearch->{_debug}=0;

# This test returns no results (but we should not get an HTTP error):
$iTest++;
$oSearch->native_query($WWW::Search::Test::bogus_query);
@aoResults = $oSearch->results();
$iResults = scalar(@aoResults);
print STDOUT (0 < $iResults) ? 'not ' : '';
print "ok $iTest Bogus query wait 10 s\n";
sleep(10);
$tt++ if (0 == $iResults);
print "Now, if some tests fails, please retry. Nomade is a ",
"busy search engine\n";

# This query returns 1 page of results:
$iTest++;
my $sQuery = 'alian';
$oSearch->maximum_to_retrieve(10);
$oSearch->native_query(WWW::Search::escape_query($sQuery),
                         { 'search_debug' => $debug, },
                      );
#@aoResults = $oSearch->results();
$iResults = $oSearch->approximate_result_count; #scalar(@aoResults);
if (($iResults < 2) || (49 < $iResults))
  {
  print STDERR " --- got $iResults results for $sQuery, but expected 2..49\n";
  print STDOUT 'not ';
  }
else { $tt++; }
print "ok $iTest query $sQuery results 2<x<50 wait 10 s\n";
sleep(10);

# This query returns 2 pages of results:
$iTest++;
$sQuery = 'pompier feu';
$oSearch->maximum_to_retrieve(10);
$oSearch->native_query(WWW::Search::escape_query($sQuery),
                         { 'search_debug' => $debug, },
                      );
#@aoResults = $oSearch->results();
$iResults = $oSearch->approximate_result_count; #scalar(@aoResults);
if (($iResults < 30) || (70 < $iResults))
  {
  print STDERR " --- got $iResults results for $sQuery, but expected 30..70\n";
  print STDOUT 'not ';
  }
else { $tt++; }
print "ok $iTest query $sQuery results 30<x<70 wait 10 s\n";
sleep(10);

# This query returns 3 pages of results:
$iTest++;
$sQuery = 'cgi';
$oSearch->native_query($sQuery,
                         { 'search_debug' => $debug, },
                      );
$oSearch->maximum_to_retrieve(10);
#@aoResults = $oSearch->results();
$iResults = $oSearch->approximate_result_count; #scalar(@aoResults);
if ($iResults < 101)
  {
  print STDERR " --- got $iResults results for $sQuery, but expected > 101\n";
  print STDOUT 'not ';
  }
else { $tt++; }
print "ok $iTest query cgi french results x>100 \n";
sleep(10);

# This query returns 3 pages of results:
$iTest++;
$sQuery = 'alianwebserver';
$oSearch->native_query($sQuery, { 'search_debug' => $debug, });
$oSearch->maximum_to_retrieve(10);
#@aoResults = $oSearch->results();
$iResults = $oSearch->approximate_result_count; #scalar(@aoResults);
if ($iResults < 101)
  {
  print STDERR " --- got $iResults results for $sQuery, but expected > 101\n";
  print STDOUT 'not ';
  }
else { $tt++; }
print "ok $iTest query $sQuery world results x>100 \n";

my $e = 0;
$e=-1 if ($tt != $ok);
exit($e);
