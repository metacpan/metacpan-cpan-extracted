# $rcs = ' $Id: altavista.t,v 1.14 2008/11/28 17:58:11 Martin Exp $ ' ;

use ExtUtils::testlib;
use Test::More no_plan;

use WWW::Search;
use WWW::Search::Test qw( tm_new_engine tm_run_test );

BEGIN { use_ok('WWW::Search::AltaVista') };
# BEGIN { use_ok('WWW::Search::AltaVista::AdvancedWeb') };

tm_new_engine('AltaVista');
my $iDebug = 0;
my $iDump = 0;

# goto DEBUG_NOW;

# goto SKIP_BASIC;
# These tests return no results (but we should not get an HTTP error):
diag("Sending 0-page query to altavista.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test(0, $WWW::Search::Test::bogus_query, 0, 0, $iDebug, $iDump);

DEBUG_NOW:
diag("Sending 1-page query to altavista.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test(0, 'noo'.'teboooks', 1, 49, $iDebug, $iDump);
my @ara = (
           ['url', 'like', qr{\Ahttp://}, 'result URL is http'],
           ['title', 'ne', '', 'result Title is not empty'],
           ['description', 'ne', '', 'result description is not empty'],
          );
WWW::Search::Test::test_most_results(\@ara, 1.00);

# goto SKIP_PHRASE_TEST;
diag("Sending phrase query to altavista.com...");
$iDebug = 0;
$iDump = 0;
# $WWW::Search::Test::oSearch->{_allow_empty_query} = 1;
$WWW::Search::Test::oSearch->native_query('junk crap bile', {
                                               search_debug => $iDebug,
                                               # Clear out the "OR" query:
                                               aqo => '',
                                               # Put our query in the
                                               # "PHRASE" slot:
                                               aqp => 'Thurn Martin',
                                              });
WWW::Search::Test::test_most_results(\@ara, 1.00);
pass;
SKIP_PHRASE_TEST:
pass;
goto ALL_DONE; # for debugging

diag("Sending multi-page query to altavista.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test(0, 'Martin '.'Thurn', 51, undef, $iDebug);
SKIP_BASIC:
pass;

tm_new_engine('AltaVista::Web');
# goto SKIP_WEB;
diag("Sending 0-page web query to altavista.com...");
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
tm_run_test(0, $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
diag("Sending multi-page web query to altavista.com...");
# This query returns 3 (or more) pages of results:
tm_run_test(0, 'Cheddar', 51, undef, $iDebug);
SKIP_WEB:
pass;
DEBUG_NOW:
pass;
ADVANCEDWEB:
pass;
tm_new_engine('AltaVista::AdvancedWeb');
# goto SKIP_ADVANCEDWEB;
diag("Sending 0-page advanced web query to altavista.com...");
$iDebug = 0;
# These tests return no results (but we should not get an HTTP error):
tm_run_test(0, $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
SKIP_ADVANCEDWEB:
pass;
ALL_DONE:
exit 0;

__END__
