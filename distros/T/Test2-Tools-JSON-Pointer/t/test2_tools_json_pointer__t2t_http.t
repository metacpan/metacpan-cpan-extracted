use Test2::Require::Module 'Test2::Tools::HTTP';
use Test2::Require::Module 'HTTP::Request';
use Test2::V0 -no_srand => 1;
use Test2::Tools::JSON::Pointer;
use Test2::Tools::HTTP;
use Test2::Tools::HTTP::Tx;
use HTTP::Request::Common;

psgi_app_add sub { [ 200, [ 'Content-Type' => 'application/json' ], [ '{"a":[1,2,3]}' ] ] };

http_request
  GET('/'),
  http_response {
    http_code 200;
    call json => { a => [1,2,3] };
    call ['json', '/a'] => [1,2,3];
  };

http_tx->note;

is(http_tx->res->json, { a => [1,2,3] });

is(http_tx->res->json('/a'), [1,2,3]);

done_testing;
