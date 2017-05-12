
use strict;
use warnings;

my $VERSION = 1.601;

use constant DEBUG_CONTENTS => 0;

use ExtUtils::testlib;
use Test::More 'no_plan';

use WWW::Search::Test 2.284;
BEGIN { use_ok('WWW::Search::Ebay::FR') };

my $iDebug;
my $iDump = 0;

tm_new_engine('Ebay::FR');
# goto DEBUG_NOW;
goto CONTENTS if DEBUG_CONTENTS;

diag("Sending 0-page query to ebay.fr...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);

MULTI_RESULT:
if (0)
  {
  diag("Sending multi-page query to ebay.fr...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns many of pages of results:
  tm_run_test('normal', 'vue', 55, undef, $iDebug);
  cmp_ok(1, '<', $WWW::Search::Test::oSearch->{requests_made}, 'got multiple pages');
  }

DEBUG_NOW:
pass;
CONTENTS:
pass;
diag("Sending 1-page query to ebay.fr to check contents...");
$iDebug = DEBUG_CONTENTS ? 2 : 0;
$iDump = 0;
$WWW::Search::Test::sSaveOnError = q{fr-1-failed.html};
tm_run_test('normal', 'gambian', 1, 99, $iDebug, $iDump);
# Now inspect the results:
my $sBidPattern = 'bid\s'. $WWW::Search::Test::oSearch->_currency_pattern;
my $qrBid = qr{\b$sBidPattern};
# print STDERR " DDD qrBid ==$qrBid==\n";
my @ara = (
           ['description', 'like', $qrBid, 'description contains bid amount'],
           ['url', 'like', qr{\Ahttp://(cgi|www)\d*\.ebay\.fr}, 'URL is from ebay.fr'],
           ['title', 'ne', q{''}, 'result Title is not empty'],
           ['change_date', 'date', 'change_date is really a date'],
           ['description', 'like', qr{([0-9]+|no)\s+bids?}, 'result bidcount is ok'],
           ['bid_count', 'like', qr{\A\d+\Z}, 'bid_count is a number'],
          );
WWW::Search::Test::test_most_results(\@ara, 1.00);
ALL_DONE:
pass;

__END__

