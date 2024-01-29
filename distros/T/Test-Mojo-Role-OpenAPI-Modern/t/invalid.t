# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use lib 't/lib';
use Helper;
use Test::Deep;

subtest 'request or response not valid' => sub {
  my $t = Test::Mojo
    ->with_roles('+OpenAPI::Modern')
    ->new($::app)
    ->openapi($::openapi);

  $t->post_ok('/foo/123', form => { salutation => 'hi' })
    ->status_is(400)
    ->content_is('kaboom')
    ->request_not_valid
    ->response_not_valid
    ->request_not_valid('Unsupported Media Type')
    ->request_not_valid(q{'/request/body': incorrect Content-Type "application/x-www-form-urlencoded"})
    ->response_not_valid(q{'/response': no response object found for code 400});

  cmp_deeply(
    $t->request_validation_result->recommended_response,
    [ 415, 'Unsupported Media Type' ],
    'request validation primary error',
  );

  is(
    Mojo::JSON::Pointer->new($t->request_validation_result->TO_JSON)->get('/errors/0/error'),
    'incorrect Content-Type "application/x-www-form-urlencoded"',
    'request validation first error',
  );

  is(
    Mojo::JSON::Pointer->new($t->response_validation_result->TO_JSON)->get('/errors/0/error'),
    'no response object found for code 400',
    'response validation error',
  );

  $t->post_ok('/foo/hello', json => { salutation => 'hi' })
    ->status_is(200)
    ->request_not_valid(q{'/request/uri/path/foo_id': got string, not integer});

  cmp_deeply(
    $t->request_validation_result->recommended_response,
    [ 400, q{'/request/uri/path/foo_id': got string, not integer} ],
    'request validation primary error falls back to first error string',
  );

  $t->post_ok('/foo/123', json => { kaboom => 'oh noes' })
    ->status_is(200)
    ->request_not_valid(q{'/request/body/kaboom': EXCEPTION: unable to find resource https://example.com/api#/$defs/i_do_not_exist})
    ->request_not_valid('Internal Server Error')
    ->response_not_valid(q{'/response/body/kaboom': EXCEPTION: unable to find resource https://example.com/api#/$defs/i_do_not_exist});

  cmp_deeply(
    $t->request_validation_result->recommended_response,
    [ 500, 'Internal Server Error' ],
    'request validation primary error obfuscates the exception',
  );

  cmp_deeply(
    $t->response_validation_result->recommended_response,
    undef,
    'response validation result does not have a primary error (response already generated!)',
  );
};

done_testing;
