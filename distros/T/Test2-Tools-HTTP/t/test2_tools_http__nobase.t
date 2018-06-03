use Test2::V0 -no_srand => 1;
use Test2::Tools::HTTP;
use HTTP::Request::Common;

psgi_app_add sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Text' ] ] };

http_request(
  GET('/'),
  http_response {
    http_code 200;
    http_content 'Text';
  },
);

done_testing;
