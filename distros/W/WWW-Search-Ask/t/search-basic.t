
# $Id: search-basic.t,v 1.5 2008/11/30 01:38:32 Martin Exp $

use ExtUtils::testlib;
use Test::More no_plan;

use WWW::Search::Test;
BEGIN
  {
  use_ok('WWW::Search::Ask');
  }

tm_new_engine('Ask');

my $iDebug = 0;
my $iDump = 0;
my @ao;

# goto TEST_NOW;

# This test returns no results (but we should not get an HTTP error):
diag("Sending bogus query to ask.com...");
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
TEST_NOW:
pass;
diag("Sending 1-page query to ask.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test('normal', 'wiz'.'arrdry', 1, 9, $iDebug, $iDump);
my @ara = (
           ['url', 'like', qr{\Ahttp://}, 'result URL is http'],
           ['url', 'unlike', qr{&#8230;}, 'url does not contain HTML ellipsis'],
           ['url', 'unlike', qr(\x{2026}), 'url does not contain Unicode ellipsis'],
           ['title', 'ne', '', 'result title is not empty'],
           ['description', 'ne', '', 'result description is not empty'],
          );
WWW::Search::Test::test_most_results(\@ara, 1.00);

diag("Sending multi-page query to ask.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test('normal', 'Martin Thurn', 21, undef, $iDebug, $iDump);
ALL_DONE:
pass;
exit 0;

__END__

