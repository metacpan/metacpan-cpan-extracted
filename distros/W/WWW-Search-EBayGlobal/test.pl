use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test', qw( count_results )) };
BEGIN { use_ok('WWW::Search::EBayGlobal') };
BEGIN { use_ok('WWW::Search::EbayUK') }; 

my $iDebug;
my $iDump = 0;

&my_new_engine('EbayUK');

# goto BYENDDATE;
# goto CONTENTS_BYENDDATE;

$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
# goto MULTI_RESULT;
$iDebug = 0;
# This query usually returns 1 page of results:
&my_test('normal', 'starballz', 1, 49, $iDebug);

MULTI_RESULT:
$iDebug = 0;
# This query returns hundreds of pages of results:
&my_test('normal', 'LEGO', 101, undef, $iDebug);

BYENDDATE:
&my_new_engine('EbayUK::ByEndDate');
$iDebug = 0;
# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
$iDebug = 0;
# This query usually returns 1 page of results:
&my_test('normal', 'starballz', 1, 49, $debug);

CONTENTS:
$iDebug = 0;
# Now get some results and inspect them:
my $o = new WWW::Search('EbayUK');
ok(ref $o);
$o->native_query('Tobago flag');
my @ao = $o->results();
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://cgi\d*\.ebay\.co\.uk},
       'result URL is really from ebay.co.uk');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  cmp_ok($oResult->change_date, 'ne', '',
         'result date is not empty');
  like($oResult->description, qr{([0-9]+|no)\s+bids?},
       'result bidcount is ok');
  } # foreach
CONTENTS_BYENDDATE:
$iDebug = 0;
# Now get some ByEndDate results and inspect them:
my $o = new WWW::Search('EBayGlobal::ByEndDate');
ok(ref $o);
$o->native_query('Tobago flag',
                   {
                    search_debug => $iDebug,
                   },
                );
my @ao = $o->results();
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://cgi\d*\.ebay\.co\.uk},
       'result URL is really from ebay.co.uk');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  cmp_ok($oResult->change_date, 'ne', '',
         'result date is not empty');
  like($oResult->description, qr{([0-9]+|no)\s+bids?},
       'result bidcount is ok');
  } # foreach

sub my_new_engine
  {
  my $sEngine = shift;
  $WWW::Search::Test::oSearch = new WWW::Search($sEngine);
  ok(ref($WWW::Search::Test::oSearch), "instantiate WWW::Search::$sEngine object");
  } # my_new_engine

sub my_test
  {
  # Same arguments as WWW::Search::Test::count_results()
  my ($sType, $sQuery, $iMin, $iMax, $iDebug, $iPrintResults) = @_;
  my $iCount = &count_results(@_);
  cmp_ok($iCount, '>=', $iMin, qq{lower-bound num-hits for query=$sQuery}) if defined $iMin;
  cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for query=$sQuery}) if defined $iMax;
  } # my_test


__END__
