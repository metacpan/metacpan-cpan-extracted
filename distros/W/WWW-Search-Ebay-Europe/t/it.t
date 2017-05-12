
# $Id: it.t,v 1.5 2013-03-03 15:03:35 Martin Exp $

use strict;
use warnings;

use ExtUtils::testlib;
use Test::More 'no_plan';

use WWW::Search::Test 2.284;
BEGIN { use_ok('WWW::Search::Ebay::IT') };

use constant DEBUG_CONTENTS => 0;

my $iDebug;
my $iDump = 0;

tm_new_engine('Ebay::IT');
# goto DEBUG_NOW;
# goto SKIP_ZERO;
goto CONTENTS if DEBUG_CONTENTS;

diag("Sending 0-page query to ebay.it...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
SKIP_ZERO:
pass;
MULTI_RESULT:
if (0)
  {
  diag("Sending multi-page query to ebay.it...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns many of pages of results:
  tm_run_test('normal', 'lego', 111, undef, $iDebug);
  cmp_ok(1, '<', $WWW::Search::Test::oSearch->{requests_made}, 'got multiple pages');
  # goto ALL_DONE;
  }

DEBUG_NOW:
pass;
CONTENTS:
pass;
$WWW::Search::Test::sSaveOnError = q{it-1-failed.html}; # }; # Emacs bug
diag("Sending 1-page query to ebay.it to check contents...");
$iDebug = DEBUG_CONTENTS ? 2 : 0;
$iDump = 0;
tm_run_test('normal', 'gambian', 1, 99, $iDebug, $iDump);
# Now inspect the results:
my $sBidPattern = 'bid\s'. $WWW::Search::Test::oSearch->_currency_pattern;
my $qrBid = qr{\b$sBidPattern};
# print STDERR " DDD qrBid ==$qrBid==\n";
my @ara = (
           ['description', 'like', $qrBid, 'description contains bid amount'],
           ['url', 'like', qr{\Ahttp://(cgi|www)\d*\.ebay\.it}, 'URL is from ebay.it'],
           ['title', 'ne', q{''}, 'result Title is not empty'],
           ['change_date', 'date', 'change_date is really a date'],
           ['description', 'like', qr{([0-9]+|no)\s+bids?}, 'result bidcount is ok'],
           ['bid_count', 'like', qr{\A\d+\z}, 'bid_count is a number'],
          );
WWW::Search::Test::test_most_results(\@ara, 1.00);
ALL_DONE:
pass;

__END__

