use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Yahoo') };

&tm_new_engine('Yahoo');
my $iDebug;
my $iDump = 0;

# goto MULTI_TEST;
# goto TEST_NOW;
# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query to yahoo.com...");
$iDebug = 0;
$iDump = 0;
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDump);
# goto THATS_ALL;
TEST_NOW:
$iDebug = 0;
$iDump = 0;
# This query returns 1 page of results:
diag("Sending 1-page query to yahoo.com...");
&tm_run_test('normal', 'res'.'sultant', 1, 99, $iDebug, $iDump);
my @ao = $WWW::Search::Test::oSearch->results();
my $iCount = scalar(@ao);
my $iCountDesc = 0;
SKIP:
  {
  skip 'got no results' unless cmp_ok(0, '<', $iCount, 'got any results');
  foreach my $oResult (@ao)
    {
    like($oResult->url, qr{\Ahttps?://}, 'result URL is http');
    cmp_ok($oResult->title, 'ne', '', 'result Title is not empty');
    # cmp_ok($oResult->size, 'ne', '', 'result size is not empty');
    $iCountDesc++ if ($oResult->description ne '');
    } # foreach
  cmp_ok(0.95, '<', $iCountDesc/$iCount, 'mostly non-empty descriptions');
  } # SKIP
# goto THATS_ALL;
MULTI_TEST:
diag("Sending multi-page query to yahoo.com...");
$iDebug = 0;
$iDump = 0;
# This query returns MANY pages of results:
&tm_run_test('normal', 'pok'.'emon', 101, undef, $iDebug, $iDump);
THATS_ALL:
exit 0;

__END__

