# $Id: null-empty.t,v 1.2 2006-04-21 20:59:08 Daddy Exp $

use ExtUtils::testlib;
use Test::More 'no_plan';

my $sMod;
BEGIN
  {
  $sMod = 'WWW::Search::Null::Empty';
  use_ok('WWW::Search');
  use_ok($sMod);
  } # end of BEGIN block
ok(my $iCount = 4);
ok(my $oSearch = new WWW::Search('Null::Empty'));
isa_ok($oSearch, $sMod);
$oSearch->native_query('Makes no difference what you search for...');
my @aoResults = $oSearch->results;
is(scalar(@aoResults), 0, 'got zero results');
is($oSearch->approximate_result_count, 0, 'got the right approx_results');
# ...But you get an HTTP::Response object with a code of 200
my $oResponse = $oSearch->response;
is($oResponse->code, 200, 'response code');
ok($oResponse->is_success, 'HTTP::Response is success');

__END__
