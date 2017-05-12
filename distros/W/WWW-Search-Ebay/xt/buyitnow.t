
# $Id: buyitnow.t,v 1.1 2015-09-13 14:30:09 Martin Exp $

use blib;
use Bit::Vector;
use Data::Dumper;
use Date::Manip;
use Test::More no_plan;

use WWW::Search::Test;
BEGIN
  {
  use_ok('WWW::Search::Ebay::BuyItNow');
  }

my $iDebug;
my $iDump = 0;

tm_new_engine('Ebay::BuyItNow');
# goto MULTI_RESULT;
# goto DEBUG_NOW;
# goto CONTENTS;

diag("Sending 0-page buy-it-now query...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);

# DEBUG_NOW:
pass;
MULTI_RESULT:
  {
  $TODO = 'WWW::Search::Ebay can not fetch multiple pages';
  diag("Sending multi-page buy-it-now query...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns hundreds of pages of results:
  tm_run_test('normal', 'LEGO', 222, undef, $iDebug);
  cmp_ok(1, '<', $WWW::Search::Test::oSearch->{requests_made}, 'got multiple pages');
  $TODO = '';
  }

# DEBUG_NOW:
pass;
TODO:
  {
  $TODO = 'sometimes there are too many of this book for sale';
  diag("Sending 1-page buy-it-now query for 12-digit UPC...");
  $iDebug = 0;
  $iDump = 0;
  tm_run_test('normal', '0-77778-60672-7' , 1, 99, $iDebug, $iDump);
  $TODO = '';
  } # end of TODO
pass;
TODO:
  {
  $TODO = 'sometimes there are zero of this item';
  diag("Sending 1-page buy-it-now query for 13-digit EAN...");
  $iDebug = 0;
  $iDump = 0;
  tm_run_test('normal', '00-75678-26382-8' , 1, 99, $iDebug, $iDump);
  $TODO = '';
  }
DEBUG_NOW:
diag("Sending 1-page buy-it-now query for 10-digit ISBN...");
TODO:
  {
  $TODO = 'sometimes there are none of this book for sale';
  $iDebug = 0;
  $iDump = 0;
  tm_run_test('normal', '0-395-52021-5' , 1, 99, $iDebug, $iDump);
  $TODO = '';
  } # end of TODO block
# goto SKIP_CONTENTS;

CONTENTS:
diag("Sending 1-page buy-it-now query to check contents...");
$iDebug = 0;
$iDump = 0;
$WWW::Search::Test::sSaveOnError = q{buyitnow-failed.html};
tm_run_test('normal', 'Kenya waterfall', 1, 199, $iDebug, $iDump);
# Now get the results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
my @ara;
push @ara, [
            url => like => qr{\Ahttp://(cgi|www)\d*\.ebay\.com},
            'result URL is really from ebay.com'
           ];
push @ara, [
            title => ne => q{''}, 'result title is not empty',
           ];
push @ara, [
            description => like => qr{no\s+bids;}, 'bid count is ok',
           ];
push @ara, [
            description => like => qr{starting\sbid}, 'result bid amount is ok'
           ];
WWW::Search::Test::test_most_results(\@ara);
SKIP_CONTENTS:
;

__END__

