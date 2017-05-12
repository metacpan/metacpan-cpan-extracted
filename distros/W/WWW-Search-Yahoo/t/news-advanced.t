
# $Id: news-advanced.t,v 1.21 2009/05/02 17:02:30 Martin Exp $

use ExtUtils::testlib;
use Test::More no_plan;

use Date::Manip;
use WWW::Search::Test;
BEGIN { use_ok('WWW::Search::Yahoo::News::Advanced') };

Date_Init('TZ=EST5EDT');

my $iDebug = 0;
my $iDump = 0;

NEWS_ADVANCED_TEST:
tm_new_engine('Yahoo::News::Advanced');

# goto DEBUG_NOW;

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query to news.yahoo.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);

DEBUG_NOW:
diag("Sending 1-page query to news.yahoo.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test('normal', 'thurn', 1, 99, $iDebug, $iDump);
# goto ALL_DONE;

# DEBUG_NOW:
diag("Sending multi-page query to news.yahoo.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test('normal', 'Japan', 51, undef, $iDebug, $iDump);
goto ALL_DONE;

pass;
# TODO:
  {
  # $TODO = qq{yahoo.com advanced search is often broken.};
  $WWW::Search::Test::oSearch->date_from('5 days ago');
  $WWW::Search::Test::oSearch->date_to  ('today');
  $iDebug = 0;
  $iDump = 0;
  tm_run_test('normal', 'Aomori', 1, 20, $iDebug, $iDump);
  # $TODO = '';
  } # end of TODO block
SKIP_REST:
pass;
ALL_DONE:
pass('all done');
exit 0;

__END__

