
# $Id: news.t,v 1.9 2005/12/15 03:57:49 Daddy Exp $

use ExtUtils::testlib;
use Test::More no_plan;

use WWW::Search::Test 2.281;
BEGIN { use_ok('WWW::Search::AltaVista') };

tm_new_engine('AltaVista::News');
# goto DEBUG_NOW;

# goto SKIP_NEWS;
my $iDebug = 0;
my $iDump = 0;
# These tests return no results (but we should not get an HTTP error):
diag("Sending 0-page normal query...");
tm_run_test(0, $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
diag("Sending 0-page normal query with plus...");
tm_run_test(0, "+perl +$WWW::Search::Test::bogus_query", 0, 0, $iDebug);
# This query returns 1 page of results:
# This query returns 2 pages of results:
DEBUG_NOW:
diag("Sending multi-page normal query...");
$iDebug = 0;
$iDump = 0;
tm_run_test(0, 'Ashburn', 51, undef, $iDebug, $iDump);
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<=', scalar(@ao), 'got any results');
my @ara = (
           ['url', 'like', qr{\Ahttp://}, 'result URL is http'],
           ['title', 'ne', q{}, 'result Title is not empty'],
           ['description', 'ne', q{}, 'result description is not empty'],
           ['source', 'ne', q{}, 'result source is not empty'],
           ['change_date', 'ne', q{}, 'result change_date is not empty'],
          );
WWW::Search::Test::test_most_results(\@ara, 0.90);
SKIP_NEWS:
pass;
# As of 2002-08, altavista.com does not have an Advanced search for
# news.
tm_new_engine('AltaVista::AdvancedNews');
goto SKIP_ADVANCEDNEWS;
$iDebug = 0;
# These tests return no results (but we should not get an HTTP error):
tm_run_test(0, $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
tm_run_test(0, "+perl +$WWW::Search::Test::bogus_query", 0, 0, $iDebug);
# This query returns 1 page of results:
# This query returns 2 pages of results:
# This query returns 3 (or more) pages of results:
$iDebug = 0;
tm_run_test(0, 'li'.'nux', 61, undef, $iDebug);
SKIP_ADVANCEDNEWS:
pass;
ALL_DONE:
exit 0;

__END__

