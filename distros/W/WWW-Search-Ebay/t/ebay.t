
# $Id: ebay.t,v 1.21 2015-06-06 19:51:07 Martin Exp $

use strict;
use warnings;

use constant DEBUG_CONTENTS => 0;

use Bit::Vector;
use Data::Dumper;
use Date::Manip;
use ExtUtils::testlib;
use Test::More;
use WWW::Search;
use WWW::Search::Test;

BEGIN
  {
  use blib;
  use_ok('WWW::Search::Ebay');
  } # end of BEGIN block

my $iDebug;
my $iDump = 0;

tm_new_engine('Ebay');
# goto ISBN;
# goto DEBUG_NOW;
goto CONTENTS if DEBUG_CONTENTS;
# goto SPELL_TEST;

diag("Sending 0-page ebay queries...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
SPELL_TEST:
pass('no-op');
# There are no hits for "laavar", make sure Ebay.pm does not return
# the "lavar" hits:
$iDebug = 0;
# tm_run_test('normal', 'laavar', 0, 0, $iDebug, 'dump');
$iDebug = 0;
# tm_run_test('normal', 'no products match this entire phrase', 0, 0, $iDebug, 'dump');
# goto ALL_DONE;

DEBUG_NOW:
pass('no-op');
MULTI_RESULT:
  {
  $TODO = 'WWW::Search::Ebay can not fetch multiple pages';
  diag("Sending multi-page ebay query...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns hundreds of pages of results:
  tm_run_test('normal', 'LEGO', 101, undef, $iDebug);
  cmp_ok(1, '<', $WWW::Search::Test::oSearch->{requests_made}, 'got multiple pages');
  $TODO = '';
  } # end of MULTI_PAGE block
# goto SKIP_CONTENTS; # for debugging

if (0)
  {
  # The intention of this test block is to retrieve a page that
  # returns hits on the exact query term, AND hits on alternate
  # spellings.  It's just too hard to find such a word that
  # consistently performs as needed.
  $TODO = "Sometimes there are NO hits for lavarr";
  diag("Sending 1-page ebay queries...");
  # There are a few hits for "lavarr", and eBay also gives us all the
  # "lavar" hits:
  $iDebug = 0;
  tm_run_test('normal', 'lavarr', 1, 99, $iDebug);
  $TODO = '';
  } # if

UPC:
  {
  $TODO = 'too hard to find a consistent EAN';
  diag("Sending 1-page ebay query for 12-digit UPC...");
  $iDebug = 0;
  $iDump = 0;
  tm_run_test('normal', '0-77778-60672-7' , 1, 99, $iDebug, $iDump);
  $TODO = '';
  } # end of UPC block
EAN:
  {
  $TODO = 'too hard to find a consistent EAN';
  diag("Sending 1-page ebay query for 13-digit EAN...");
  $iDebug = 0;
  $iDump = 0;
  tm_run_test('normal', '00-77778-60672-7' , 1, 99, $iDebug, $iDump);
  $TODO = '';
  } # end of EAN block
ISBN:
  {
  $TODO = q{I don't know why, but this test has more false negatives than almost any other};
  diag("Sending 1-page ebay query for 10-digit ISBN...");
  $iDebug = 0;
  $iDump = 0;
  tm_run_test('normal', '0-553-09606-0' , 1, 99, $iDebug, $iDump);
  $TODO = q{};
  } # end of ISBN block
# goto SKIP_CONTENTS;

CONTENTS:
diag("Sending 1-page ebay query to check contents...");
$iDebug = DEBUG_CONTENTS ? 2 : 0;
$iDump = 0;
$WWW::Search::Test::sSaveOnError = q{ebay-1-failed.html}; # }; # Emacs bug
my $sQuery = 'trinidad tobago flag';
# $sQuery = 'church spread wings';  # Special debugging
tm_run_test('normal', $sQuery, 1, 99, $iDebug, $iDump);
# Now get the results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
my $sBidPattern = 'bid\s+'. $WWW::Search::Test::oSearch->_currency_pattern .'\s?[,.0-9]+';
my $qrBid = qr{\b$sBidPattern};
my @ara = (
           ['description', 'like', $qrBid, 'description contains bid amount'],
           ['description', 'like', qr{Item #\d+;}, 'description contains item #'],
           ['url', 'like', qr(\Ahttp://(cgi|www)\d*\.ebay\.com), # ), # Emacs bug
            q'URL is from ebay.com'], # '], # Emacs bug
           ['title', 'ne', 'q{}', 'result Title is not empty'],
           ['change_date', 'date', 'change_date is really a date'],
           ['description', 'like', qr{\b(\d+|no)\s+bids?}, # }, # Emacs bug
            'result bidcount is ok'],
           ['bid_count', 'like', qr{\A\d+\Z}, 'bid_count is a number'],
           # ['shipping', 'like', qr{\A(free|[0-9\$\.]+)\Z}i, 'shipping looks like a money value'],
           ['category', 'like', qr{\A-?\d+\Z}, 'category is a number'],
          );
WWW::Search::Test::test_most_results(\@ara, 1.00);
# Sanity check for new category list parsing:
# print STDERR Dumper($WWW::Search::Test::oSearch->{categories});

SKIP_CONTENTS:
pass('no-op');
ALL_DONE:
pass('all done');

done_testing();

__END__

