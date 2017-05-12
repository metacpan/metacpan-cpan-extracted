# $Id: null-error.t,v 1.1 2006-04-21 20:58:01 Daddy Exp $

use ExtUtils::testlib;
use Test::More 'no_plan';

my $sMod;
BEGIN
  {
  $sMod = 'WWW::Search::Null::Error';
  use_ok('WWW::Search');
  use_ok($sMod);
  } # end of BEGIN block
ok(my $iCount = 4);
ok(my $oSearch = new WWW::Search('Null::Error'));
isa_ok($oSearch, $sMod);
$oSearch->native_query('Makes no difference what you search for...');
my @aoResults = $oSearch->results;
is(scalar(@aoResults), 0, 'got zero results');
is($oSearch->approximate_result_count, 0, 'got the right approx_results');
# ...But you get an HTTP::Response object with a code of 200
my $oResponse = $oSearch->response;
is($oResponse->code, 500, 'response code');
ok(! $oResponse->is_success, 'got an HTTP failure');

__END__
