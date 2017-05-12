
# $Id: gui.t,v 1.13 2009/05/02 17:02:30 Martin Exp $

use ExtUtils::testlib;
use Test::More no_plan;

use WWW::Search::Test;
BEGIN { use_ok('WWW::Search::Yahoo') };

my $iDebug;
my $iDump = 0;

GUI_TEST:
$iDebug = 0;
tm_new_engine('Yahoo');
# goto MULTI;
if (0)
  {
  # NOTE: As of 2009-05, the Yahoo GUI automatically does
  # spell-checking and if your query only returns one page of results,
  # it automatically chooses the closest word and shows those results
  # instead.
  diag("Sending 1-page query to yahoo.com...");
  # This GUI query returns 1 page of results:
  $iDebug = 0;
  tm_run_test('gui', 'wiz'.'radary', 1, 9, $iDebug);
  } # if
MULTI:
diag("Sending multi-page query to yahoo.com...");
$iDebug = 0;
# This GUI query returns many pages of results; gui search returns 10
# per page:
tm_run_test('gui', 'pokemon', 21, undef, $iDebug);
exit 0;

__END__
