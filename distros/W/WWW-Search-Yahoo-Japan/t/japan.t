
# $Id: japan.t,v 1.4 2008/12/25 18:56:02 Martin Exp $

use blib;
use Test::More no_plan;

use WWW::Search::Test;
BEGIN
  {
  use_ok('WWW::Search::Yahoo::Japan');
  }

tm_new_engine('Yahoo::Japan');
my $iDebug = 0;
my $iDump = 0;

# goto TEST_NOW;
# goto MULTI_TEST;

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query...");
$iDebug = 0;
$iDump = 0;
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDump);
# goto ALL_DONE; # for testing
TEST_NOW:
pass();
$iDebug = 0;
$iDump = 0;
# This query returns 1 page of results:
diag("Sending 1-page query...");
tm_run_test('normal', 'wiz'.'erdery', 1, 99, $iDebug, $iDump);
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got any results');
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://},
       'result URL is http');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  cmp_ok($oResult->description, 'ne', '',
         'result description is not empty');
  } # foreach
# goto ALL_DONE;
pass();
MULTI_TEST:
pass();
diag("Sending multi-page query...");
$iDebug = 0;
$iDump = 0;
# This query returns MANY pages of results:
tm_run_test('normal', "\xCB\xBD", 111, undef, $iDebug, $iDump);

ALL_DONE:
pass();
exit 0;

__END__

