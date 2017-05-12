
# $Id: de.t,v 1.9 2005/12/15 03:55:51 Daddy Exp $

use ExtUtils::testlib;
use Test::More no_plan;

use WWW::Search::Test 2.284;
BEGIN
  {
  use_ok('WWW::Search::AltaVista');
  use_ok('WWW::Search::AltaVista::DE');
  } # end of BEGIN block

# goto SKIP_BASIC;
tm_new_engine('AltaVista::DE');

# goto DEBUG_NOW;

my $iDebug = 0;
diag("Sending 0-page query...");
# These tests return no results (but we should not get an HTTP error):
tm_run_test(0, $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
diag("Sending 1-page query...");
# The following query returns one page of results:
$iDebug = 0;
tm_run_test(0, '"Martin Thurn-Mitt'.'hoff"', 1, 49, $iDebug);
my @ara = (
           ['url', 'like', qr{\Ahttp://}, 'result URL is http'],
           ['title', 'ne', '', 'result Title is not empty'],
           ['description', 'ne', '', 'result description is not empty'],
          );
WWW::Search::Test::test_most_results(\@ara, 1.00);

DEBUG_NOW:
pass;
diag("Sending multi-page query...");
# The following query returns many pages of results:
$iDebug = 0;
tm_run_test(0, 'Berlin', 101, undef, $iDebug);
ALL_DONE:
pass;
exit 0;

__END__
