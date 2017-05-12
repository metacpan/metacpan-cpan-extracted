
# $Id: enddate.t,v 1.14 2015-06-06 19:51:07 Martin Exp $

use strict;
use warnings;

use blib;
use Data::Dumper;
use Date::Manip;
$ENV{TZ} = 'EST5EDT';
# Date_Init('TZ=EST5EDT');
use ExtUtils::testlib;
use Test::More 'no_plan';
use WWW::Search;
use WWW::Search::Test;

use constant DEBUG_DATE => 0;

my $iDebug = 0;
my $iDump = 0;

tm_new_engine('Ebay::ByEndDate');
# goto TEST_NOW;

pass('no-op');
TEST_NOW:
pass('no-op');
diag("Sending end-date query...");
$iDebug = 0;
$iDump = 0;
# We need a query that returns "Featured Items" _and_ items that end
# in a few minutes.  This one attracts Rock'n'Roll fans and
# philatelists:
TODO:
  {
  $TODO = 'We only need one page of results in order to test the end-date sort';
  tm_run_test('normal', 'zeppelin', 45, 49, $iDebug, $iDump);
  }
$TODO = '';
# goto ALL_DONE;  # for debugging

# Now get some ByEndDate results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
my $sDatePrev = 'yesterday';
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://(cgi|www)\d*\.ebay\.com},
       'result URL really is from ebay.com');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  like($oResult->description, qr{([0-9]+|no)\s+bids?},
       'result bidcount is ok');
  my $sDate = $oResult->change_date || '';
  DEBUG_DATE && diag(qq{raw result date is '$sDate'});
  diag(Dumper($oResult)) unless isnt($sDate, '');
  my $iCmp = Date_Cmp($sDatePrev, $sDate);
  cmp_ok($iCmp, '<=', 0, 'result is in order by end date');
  $sDatePrev = $sDate;
  } # foreach
pass('no-op');
ALL_DONE:
pass('no-op');
exit 0;

__END__

