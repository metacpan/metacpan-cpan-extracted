
# $Id: search-basic.t,v 1.7 2008/07/27 16:33:24 Martin Exp $

use blib;
use Test::More no_plan;

use WWW::Search::Test;
BEGIN
  {
  use_ok('WWW::Search::Search');
  } # end of BEGIN block

tm_new_engine('Search');

my $iDebug = 0;
my $iDump = 0;
my @ao;

# goto TEST_NOW;

# This test returns no results (but we should not get an HTTP error):
diag("Sending bogus query to search.com...");
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
# TEST_NOW:
diag("Sending 1-page query to search.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test('normal', 'foooo'.'ooooooooolish', 1, 9, $iDebug, $iDump);
# Look at some actual results:
@ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got any results');
foreach my $oResult (@ao)
  {
  next unless ref($oResult);
  like($oResult->url, qr{\Ahttp://},
       'result URL is http');
  unlike($oResult->url, qr{&#8230;}, 'url does not contain HTML ellipsis');
  unlike($oResult->url, qr(\x{2026}), 'url does not contain Unicode ellipsis');
  cmp_ok($oResult->title, 'ne', '',
         'result title is not empty');
  cmp_ok($oResult->description, 'ne', '',
         'result description is not empty');
  } # foreach
# goto ALL_DONE; # for debugging
TEST_NOW:
diag("Sending multi-page query to search.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test('normal', 'the lovely Britney Spears', 21, undef, $iDebug, $iDump);
ALL_DONE:
exit 0;

__END__
