
use warnings;
use strict;

my $VERSION = 1.05;

use blib;
use Bit::Vector;
use Data::Dumper;
use Test::More 'no_plan';

use WWW::Search::Test;
BEGIN
  {
  use_ok('WWW::Search::Ebay::Category');
  } # end of BEGIN block

my $iDebug;
my $iDump = 0;

tm_new_engine('Ebay::Category');
$WWW::Search::Test::sSaveOnError = q{category-failed.html};
# goto MULTI_RESULT;
# goto DEBUG_NOW;
# goto CONTENTS;

diag("Sending 0-page category query...");
$iDebug = 0;
# This test returns no results (but we should not get any errors):
WWW::Search::Test::_tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug, 0);

# goto SKIP_CONTENTS;

# DEBUG_NOW:
pass;
goto SKIP_MULTI_RESULT;
MULTI_RESULT:
  {
  $TODO = 'WWW::Search::Ebay can not fetch multiple pages';
  diag("Sending multi-page category query...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns dozens of pages of results:
  tm_run_test('normal', '1380', 222, undef, $iDebug);
  cmp_ok(1, '<', $WWW::Search::Test::oSearch->{requests_made}, 'got multiple pages');
  $TODO = '';
  } # end of MULTI_RESULT block
SKIP_MULTI_RESULT:
pass;
DEBUG_NOW:
pass;
CONTENTS:
diag("Sending 1-page category query to check contents...");
$iDebug = 0;
$iDump = 0;
# 175817 is "Credit Services"
tm_run_test('normal', 175817, 1, 199, $iDebug, $iDump);
# Now get the results and inspect them:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got some results');
# We perform this many tests on each result object:
my $iTests = 5;
my $iAnyFailed = 0;
my ($iVall, %hash);
my $oV = new Bit::Vector($iTests);
$oV->Fill;
$iVall = $oV->to_Dec;
foreach my $oResult (@ao)
  {
  $oV->Bit_Off(0) unless like($oResult->url, qr{\Ahttps?://[^.]+\.ebay\.com},
                              'result URL is really from ebay.com');
  $oV->Bit_Off(1) unless cmp_ok($oResult->title, 'ne', '',
                                'result Title is not empty');
  $oV->Bit_Off(3) unless like($oResult->description, qr{(\d+|no)\sbids?;},
                              'result bid count is ok');
  $oV->Bit_Off(4) unless like($oResult->description, qr{(starting|current)\sbid\s},
                              'result bid amount is ok');
  my $iV = $oV->to_Dec;
  if ($iV < $iVall)
    {
    $hash{$iV} = $oResult;
    $iAnyFailed++;
    } # if
  } # foreach
if ($iAnyFailed)
  {
  diag(" Here are results that exemplify the failures:");
  while (my ($sKey, $sVal) = each %hash)
    {
    diag(Dumper($sVal));
    } # while
  } # if
SKIP_CONTENTS:
pass;

__END__

