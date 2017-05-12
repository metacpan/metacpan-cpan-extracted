
# $Id: bysellerid.t,v 1.1 2015-09-13 14:30:09 Martin Exp $

use constant DEBUG_CONTENTS => 0;

use Date::Manip;
use ExtUtils::testlib;
use Test::More no_plan;

use WWW::Search;
use WWW::Search::Test;
BEGIN
  {
  use blib;
  use_ok('WWW::Search::Ebay::BySellerID');
  } # end of BEGIN block

my $iDebug;
my $iDump;

tm_new_engine('Ebay::BySellerID');
# goto DEBUG_NOW;
goto CONTENTS if DEBUG_CONTENTS;
# goto CONTENTS;

diag("Sending 0-page seller ID query...");
$iDebug = 0;
$iDump = 0;
# This test returns no results (but we should not get an HTTP error):
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDump);

goto SKIP_MULTI;
pass('no-op');
# DEBUG_NOW:
pass('no-op');
MULTI_RESULT:
  {
  $TODO = 'WWW::Search::Ebay can not fetch multiple pages';
  diag("Sending multi-page seller ID query...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns many pages of results:
  tm_run_test('normal', 'toymom21957', 200, undef, $iDebug);
  cmp_ok(1, '<', $WWW::Search::Test::oSearch->{requests_made}, 'got multiple pages');
  $TODO = q{};
  }

DEBUG_NOW:
pass('no-op');
SKIP_MULTI:
pass('no-op');
CONTENTS:
diag("Sending 1-page seller ID query to check contents...");
$iDebug = DEBUG_CONTENTS ? 2 : 0;
$iDump = 0;
$WWW::Search::Test::sSaveOnError = q{bysellerid-failed.html};
# local $TODO = 'Too hard to find a seller with consistently one page of auctions';
tm_run_test('normal', 'oldschool2017', 1, 199, $iDebug, $iDump);
# Now get the results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
my @ara = (
           ['url', 'like', qr{\Ahttp://(cgi|www)\d*\.ebay\.com}, 'URL is really from ebay.com'],
           ['title', 'ne', 'q{}', 'Title is not empty'],
           ['change_date', 'date', 'change_date is really a date'],
           ['description', 'like', qr{Item #\d+;}, 'description contains item #'],
           ['description', 'like', qr{\b(\d+|no)\s+bids?}, # }, # Emacs bug
            'result bidcount is ok'],
           ['bid_count', 'like', qr{\A\d+\Z}, 'bid_count is a number'],
          );
WWW::Search::Test::test_most_results(\@ara, 0.95);

__END__

