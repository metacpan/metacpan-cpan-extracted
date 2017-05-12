
# $Id: de.t,v 1.4 2008/03/06 03:54:55 Daddy Exp $

use strict;
use warnings;

use ExtUtils::testlib;
use Test::More 'no_plan';

BEGIN
  {
  use_ok('WWW::Search');
  use_ok('WWW::Search::Test');
  use_ok('WWW::Search::Yahoo::DE');
  use_ok('WWW::Search::Yahoo::Germany');
  use_ok('WWW::Search::Yahoo::Deutschland');
  } # end of BEGIN block

&tm_new_engine('Yahoo::Deutschland');
my $iDebug;
my $iDump;

# goto SINGLE_TEST;
# goto MULTI_TEST;

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query...");
$iDebug = 0;
$iDump = 0;
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDump);
# goto ALL_DONE;
# goto MULTI_TEST;
SINGLE_TEST:
&tm_new_engine('Yahoo::DE');
$iDebug = 0;
$iDump = 0;
# This query returns 1 page of results:
diag("Sending 1-page query...");
&tm_run_test('normal', '+wiz'.'arrdry', 1, 99, $iDebug, $iDump);
my @ao = $WWW::Search::Test::oSearch->results();
my $iCount = scalar(@ao);
cmp_ok(0, '<', $iCount, 'got any results');
my $iCountDesc = 0;
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttps?://},
       'result URL is http');
  cmp_ok($oResult->title, 'ne', q{},
         'result Title is not empty');
  $iCountDesc++ if ($oResult->description ne q{});
  } # foreach
cmp_ok(0.95, '<', $iCountDesc/$iCount, 'mostly non-empty descriptions');
# goto ALL_DONE;

MULTI_TEST:
&tm_new_engine('Yahoo::Germany');
diag("Sending multi-page query...");
$iDebug = 0;
$iDump = 0;
# This query returns MANY pages of results:
&tm_run_test('normal', "Thurn", 101, undef, $iDebug, $iDump);

ALL_DONE:
exit 0;

__END__

