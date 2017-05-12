# $Id: null-count.t,v 1.2 2008-01-21 03:01:38 Daddy Exp $

use ExtUtils::testlib;
use Test::More 'no_plan';

my $sMod;
BEGIN
  {
  $sMod = 'WWW::Search::Null::Count';
  use_ok('WWW::Search');
  use_ok($sMod);
  } # end of BEGIN block
ok(my $iCount = 4);
ok(my $oSearch = new WWW::Search('Null::Count',
                                 '_null_count' => $iCount,
                                )
  );
isa_ok($oSearch, $sMod);
$oSearch->native_query('Makes no difference what you search for...');
ok(my @aoResults = $oSearch->results);
is(scalar(@aoResults), $iCount, 'got the right number of results');
is($oSearch->approximate_result_count, $iCount, 'got the right approx_results');
ok(my $oResult = shift @aoResults);
is($oResult->url, "url1", 'url');
is(scalar(@{$oResult->related_urls}), $iCount, 'got N related_urls');
is(scalar(@{$oResult->related_titles}), $iCount, 'got N related_titles');
is(scalar(@{$oResult->urls}), $iCount+1, 'got N+1 urls');
ok(my $raURL = $oResult->urls);
# diag("sURL =$sURL=");
is(scalar(@{$raURL}), $iCount+1, 'got N+1 urls in arrayref');
# Additional calls for coverage:
my $o5 = new WWW::Search('Null::Count');
$o5->native_query('fubar');
$o5->results;

__END__
