
# $Id: basic.t,v 1.11 2008/12/14 23:59:46 Martin Exp $

use ExtUtils::testlib;
use Test::More no_plan;

use WWW::Search::Test;
BEGIN
  {
  use_ok('WWW::Search::Lycos');
  }

tm_new_engine('Lycos');

my $iDebug = 0;
my $iDump = 0;
my @ao;

# goto TEST_NOW; # for debugging

# This test returns no results (but we should not get an HTTP error):
diag("Sending bogus query to lycos.com...");
tm_run_test('normal', qq{"$WWW::Search::Test::bogus_query"}, 0, 0, $iDebug);

TEST_NOW:
pass;
diag("Sending 1-page query to lycos.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test('normal', 'establishmentarianistic'.'ally', 1, 9, $iDebug, $iDump);
# Look at some actual results:
@ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got any results');
foreach my $oResult (@ao)
  {
  next unless ref($oResult);
  like($oResult->url, qr{\Ahttp://},
       'result URL is http');
  cmp_ok($oResult->title, 'ne', '',
         'result title is not empty');
  cmp_ok($oResult->description, 'ne', '',
         'result description is not empty');
  } # foreach

# goto ALL_DONE; # for debugging

diag("Sending multi-page query to lycos.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test('normal', 'the lovely Britney Spears', 21, undef, $iDebug, $iDump);

ALL_DONE:
pass;
exit 0;

__END__
