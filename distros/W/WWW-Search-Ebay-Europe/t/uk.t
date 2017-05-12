
# $Id: uk.t,v 1.9 2013-03-17 01:11:42 Martin Exp $

use strict;
use warnings;

use constant DEBUG_CONTENTS => 0;

use ExtUtils::testlib;
use Test::More 'no_plan';

use WWW::Search::Test 2.284;
BEGIN { use_ok('WWW::Search::Ebay::UK') };

my $iDebug;
my $iDump = 0;

tm_new_engine('Ebay::UK');
# goto DEBUG_NOW;
goto CONTENTS if DEBUG_CONTENTS;
# goto MULTI_RESULT;

diag("Sending 0-page query to ebay.co.uk...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);

DEBUG_NOW:
pass;
MULTI_RESULT:
if (0)
  {
  pass;
  diag("Sending multi-page query to ebay.co.uk...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns hundreds of pages of results:
  $WWW::Search::Test::sSaveOnError = q{uk-multi-failed.html};
  tm_run_test('normal', 'LEGO', 266, undef, $iDebug);
  cmp_ok(1, '<', $WWW::Search::Test::oSearch->{requests_made}, 'got multiple pages');
  # goto ALL_DONE;
  } # if

CONTENTS:
diag("Sending 1-page query to ebay.co.uk to check contents...");
$iDebug = DEBUG_CONTENTS ? 2 : 0;
$iDump = 0;
$WWW::Search::Test::sSaveOnError = q{uk-1-failed.html};
tm_run_test('normal', 'Trinidad mint set', 1, 49, $iDebug, $iDump);
# Now inspect the results:
my $sBidPattern = 'bid\s'. $WWW::Search::Test::oSearch->_currency_pattern .'\s?[,.0-9]+';
my $qrBid = qr{\b$sBidPattern};
# print STDERR " DDD qrBid ==$qrBid==\n";
my @ara = (
           ['description', 'like', $qrBid, 'description contains bid amount'],
           ['url', 'like', qr{\Ahttp://(cgi|www)\d*\.ebay\.co.uk}, 'URL is from ebay.co.uk'],
           ['title', 'ne', q{''}, 'result Title is not empty'],
           ['change_date', 'date', 'change_date is really a date'],
           ['description', 'like', qr{([0-9]+|no)\s+bids?}, 'result bidcount is ok'],
           ['bid_count', 'like', qr{\A\d+\Z}, 'bid_count is a number'],
          );
WWW::Search::Test::test_most_results(\@ara, 1.00);
ALL_DONE:
pass;

__END__

