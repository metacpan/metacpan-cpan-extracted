#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use JSON::MaybeXS qw( encode_json decode_json );
use MIME::Base64 qw( encode_base64 );
use HTTP::Response;
use URI;

use WWW::Crawl4AI::Client;

my $client = WWW::Crawl4AI::Client->new( base_url => 'http://localhost:11235' );

sub json_response {
  my ( $data, $code, $msg ) = @_;
  return HTTP::Response->new(
    $code // 200, $msg // 'OK',
    [ 'Content-Type' => 'application/json' ],
    encode_json($data),
  );
}

subtest 'screenshot: request shape + bytes out' => sub {
  my $req = $client->screenshot_request(
    'https://example.com',
    wait_for => 2, wait_for_images => 1, output_path => '/tmp/x.png',
  );
  is $req->method, 'POST', 'POST';
  is $req->uri, 'http://localhost:11235/screenshot', 'screenshot uri';
  my $body = decode_json( $req->content );
  is $body->{url}, 'https://example.com', 'url in body';
  is $body->{screenshot_wait_for}, 2, 'wait_for -> screenshot_wait_for';
  is $body->{output_path}, '/tmp/x.png', 'output_path forwarded';
  like encode_json($body), qr/"wait_for_images":true/, 'wait_for_images as JSON bool';

  my $png = "\x89PNG\r\n\x1a\nrealbytes";
  my $out = $client->parse_screenshot_response(
    json_response( { success => JSON::MaybeXS::true(), screenshot => encode_base64( $png, '' ) } )
  );
  is $out, $png, 'base64 decoded to raw image bytes';
};

subtest 'screenshot: omitted booleans stay out of the body' => sub {
  my $body = decode_json( $client->screenshot_request('https://example.com')->content );
  ok !exists $body->{wait_for_images}, 'no wait_for_images key when not given';
  ok !exists $body->{screenshot_wait_for}, 'no wait_for key when not given';
};

subtest 'pdf: request + bytes out' => sub {
  my $req = $client->pdf_request( 'https://example.com', output_path => '/tmp/x.pdf' );
  is $req->uri, 'http://localhost:11235/pdf', 'pdf uri';
  is decode_json( $req->content )->{output_path}, '/tmp/x.pdf', 'output_path forwarded';

  my $pdf = "%PDF-1.4 realbytes";
  my $out = $client->parse_pdf_response(
    json_response( { success => JSON::MaybeXS::true(), pdf => encode_base64( $pdf, '' ) } )
  );
  is $out, $pdf, 'base64 decoded to raw pdf bytes';
};

subtest 'html: request + string out' => sub {
  my $req = $client->html_request('https://example.com');
  is $req->uri, 'http://localhost:11235/html', 'html uri';
  my $out = $client->parse_html_response(
    json_response( { html => '<h1>Hi</h1>', url => 'https://example.com', success => JSON::MaybeXS::true() } )
  );
  is $out, '<h1>Hi</h1>', 'html string returned';
};

subtest 'execute_js: scalar coerced, page normalized, js_result attached' => sub {
  my $req = $client->execute_js_request( 'https://example.com', 'return document.title' );
  is $req->uri, 'http://localhost:11235/execute_js', 'execute_js uri';
  is_deeply decode_json( $req->content )->{scripts}, ['return document.title'], 'scalar script coerced to arrayref';

  my $arr = $client->execute_js_request( 'https://example.com', [ 'a()', 'b()' ] );
  is_deeply decode_json( $arr->content )->{scripts}, [ 'a()', 'b()' ], 'arrayref kept';

  my $page = $client->parse_execute_js_response(
    json_response( {
      url => 'https://example.com', status_code => 200,
      markdown => 'real content ' x 10,
      js_execution_result => { results => ['Example Domain'], success => JSON::MaybeXS::true() },
    } )
  );
  is $page->{url}, 'https://example.com', 'normalized page url';
  like $page->{markdown}, qr/real content/, 'markdown normalized';
  is_deeply $page->{js_result}{results}, ['Example Domain'], 'js_result carried through';
};

subtest 'execute_js: missing script dies' => sub {
  isnt exception { $client->execute_js_request('https://example.com') }, undef, 'no script rejected';
  isnt exception { $client->execute_js_request( 'https://example.com', [] ) }, undef, 'empty scripts rejected';
};

subtest 'llm: GET with escaped page url + query params' => sub {
  my $req = $client->llm_request(
    'https://example.com/p?x=1', 'Who wrote this?',
    provider => 'openai/gpt-4o', temperature => 0.2,
  );
  is $req->method, 'GET', 'GET';
  my $u = URI->new( $req->uri );
  like "$u", qr{/llm/https%3A}, 'page url escaped into the path segment';
  unlike "$u", qr{/llm/https://}, 'page url not left raw in path';
  my %q = $u->query_form;
  is $q{q},           'Who wrote this?', 'question carried';
  is $q{provider},    'openai/gpt-4o',   'provider carried';
  is $q{temperature}, '0.2',             'temperature carried';

  my $ans = $client->parse_llm_response( json_response( { answer => 'Some answer' } ) );
  is $ans, 'Some answer', 'answer extracted';
};

subtest 'token: request + decode' => sub {
  my $req = $client->token_request('me@example.com');
  is $req->uri, 'http://localhost:11235/token', 'token uri';
  is decode_json( $req->content )->{email}, 'me@example.com', 'email in body';

  my $tok = $client->parse_token_response(
    json_response( { email => 'me@example.com', access_token => 'jwt.abc', token_type => 'bearer' } )
  );
  is $tok->{access_token}, 'jwt.abc', 'access_token decoded';
  is $tok->{token_type},   'bearer',  'token_type decoded';
};

subtest 'artifact parsers raise on failure / empty' => sub {
  my $err = exception {
    $client->parse_screenshot_response( json_response( { success => JSON::MaybeXS::false() } ) );
  };
  isa_ok $err, 'WWW::Crawl4AI::Error', 'empty screenshot -> error';
  is $err->type, 'content', 'classified as content error';

  my $api = exception {
    $client->parse_pdf_response( json_response( { detail => 'boom' }, 500, 'Server Error' ) );
  };
  isa_ok $api, 'WWW::Crawl4AI::Error', 'non-2xx -> error';
  is $api->type, 'api', 'classified as api error';
};

done_testing;
