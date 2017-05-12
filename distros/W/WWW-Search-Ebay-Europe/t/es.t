
use strict;
use warnings;

my $VERSION = 1.501;

use constant DEBUG_CONTENTS => 0;

use ExtUtils::testlib;
use Test::More 'no_plan';

use WWW::Search::Test 2.284;
BEGIN { use_ok('WWW::Search::Ebay::ES') };

my $iDebug;
my $iDump = 0;

tm_new_engine('Ebay::ES');
# goto DEBUG_NOW;
goto CONTENTS if DEBUG_CONTENTS;

diag("Sending 0-page query to ebay.es...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);

pass;
MULTI_RESULT:
if (0)
  {
  diag("Sending multi-page query to ebay.es...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns many of pages of results:
  tm_run_test('normal', 'cuba', 52, undef, $iDebug);
  }

DEBUG_NOW:
pass;
CONTENTS:
diag("Sending 1-page auction query to ebay.es to check contents...");
$iDebug = DEBUG_CONTENTS ? 2 : 0;
$iDump = 0;
tm_run_test('normal', 'trinidad billete', 1, 99, $iDebug, $iDump);
# Now inspect the results:
my $sBidPattern = 'bid\s'. $WWW::Search::Test::oSearch->_currency_pattern;
my $qrBid = qr{\b$sBidPattern};
# print STDERR " DDD qrBid ==$qrBid==\n";
my @ara = (
           ['description', 'like', $qrBid, 'description contains bid amount'],
           ['url', 'like', qr{\Ahttp://(cgi|www)\d*\.ebay\.es}, 'URL is from ebay.es'],
           ['title', 'ne', q{''}, 'result Title is not empty'],
           ['change_date', 'date', 'change_date is really a date'],
           ['description', 'like', qr{([0-9]+|no)\s+bids?}, 'result bidcount is ok'],
           ['bid_count', 'like', qr{\A\d+\Z}, 'bid_count is a number'],
          );
WWW::Search::Test::test_most_results(\@ara, 1.00);
ALL_DONE:
pass('all done');

__END__

