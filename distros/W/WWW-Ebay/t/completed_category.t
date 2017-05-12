
# $Id: completed_category.t,v 1.4 2015-09-13 15:59:11 Martin Exp $

use strict;
use warnings;

use constant DEBUG_CONTENT => 0;

use Bit::Vector;
use Data::Dumper;
use Date::Manip;
use Test::More;
use WWW::Search::Test;

BEGIN
  {
  use ExtUtils::testlib;
  use_ok('WWW::Search::Ebay::Completed::Category');
  } # end of BEGIN block

my $iDebug = 0;
my $iDump = 0;

tm_new_engine('Ebay::Completed::Category');
SKIP:
  {
  # See if ebay userid is in environment variable:
  my $sUserID = $ENV{EBAY_USERID} || '';
  my $sPassword = $ENV{EBAY_PASSWORD} || '';
  if (($sUserID eq '') || ($sPassword eq ''))
    {
    diag("In order to test this module, set environment variables EBAY_USERID and EBAY_PASSWORD.");
    if (0)
      {
      print <<'PROMPT';
Type an eBay userid and password to be used for testing.
(You can set environment variables EBAY_USERID and EBAY_PASSWORD
 to avoid this prompt next time.)
eBay userid: 
PROMPT
      # Read one line from STDIN:
      local $/ = "\n";
      $sUserID = <STDIN>;
      chomp $sUserID;
      # Don't ask for password if they didn't enter a userid:
      if ($sUserID ne '')
        {
        print "password: ";
        $sPassword = <STDIN>;
        chomp $sPassword;
        } # if
      } # if
    } # if
  skip "eBay userid/password not supplied", 11 if (($sUserID   eq '') ||
                                                   ($sPassword eq ''));
  diag("log in as $sUserID...");
  ok($WWW::Search::Test::oSearch->login($sUserID, $sPassword), 'logged in');
  DEBUG_CONTENT && goto TEST_CONTENT;
  # goto DEBUG_NOW;

  # This test returns no results (but we should not get an HTTP error):
  diag("sending zero-page query...");
  $iDebug = 0;
  tm_run_test('normal', 999_999_999, 0, 0, $iDebug);
 MULTI_PAGE:
    {
    $TODO = q{can not follow ebay's next-page link};
    diag("sending multi-page query...");
    $iDebug = 0;
    $iDump = 0;
    # Disney pins, hundreds of pages of results
    tm_run_test('normal', '38004', 444, undef, $iDebug, $iDump);
    $TODO = q{};
    } # end of MULTI_PAGE block

 DEBUG_NOW:
  pass;
 TEST_CONTENT:
  diag("sending one-page query...");
  $iDebug = DEBUG_CONTENT ? 2 : 0;
  $iDump = 0;
  $WWW::Search::Test::sSaveOnError = q{completed_category-failed.html};
  # Category 179370 is "Cape Verde stamps"
  tm_run_test('normal', '179370', 1, 199, $iDebug, $iDump);
  # Now get the results and inspect them:
  my @ao = $WWW::Search::Test::oSearch->results();
  cmp_ok(0, '<', scalar(@ao), 'got some results');
  my @ara = (
             ['url', 'like', qr{\Ahttp://(cgi|www)\d*\.ebay\.com}i, 'URL is really from ebay.com'],
             ['title', 'ne', 'q{}', 'Title is not empty'],
             # ['end_date', 'date', 'end_date is really a date'],
             ['description', 'like', qr{Item #\d+;}, 'description contains item #'],
             ['description', 'like', qr{\d+\.\d+(\Z|\s\(?)}, 'description contains result amount'],
             ['description', 'like', qr{\b(\d+|no)\s+bids?|Buy-It-Now}, # }, # Emacs bug
              'result bidcount is ok'],
             ['bid_count', 'like', qr{\A\d+\z}, 'bid_count is a number'],
            );
  WWW::Search::Test::test_most_results(\@ara, 0.95);
  DEBUG_CONTENT && goto ALL_DONE;
  } # SKIP

ALL_DONE:
done_testing();

__END__
