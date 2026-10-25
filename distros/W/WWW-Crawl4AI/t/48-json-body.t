#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Request;
use HTTP::Response;
use Safe::Isa;
use WWW::Crawl4AI::Client;

# An answer that is no JSON is an error: a captive portal or a proxy answers
# 200 with an HTML body, and the parsers used to answer quietly wrong.

my $client = WWW::Crawl4AI::Client->new( base_url => 'http://localhost:11235' );

my $HTML = '<html><body>Please log in to the portal</body></html>';

sub response_with {
  my ( $body, %opt ) = @_;
  my $res = HTTP::Response->new(
    $opt{code} // 200,
    $opt{message} // 'OK',
    [ 'Content-Type' => $opt{type} // 'text/html; charset=utf-8' ],
    $body,
  );
  $res->request(
    HTTP::Request->new( $opt{method} // 'GET', 'http://localhost:11235' . ( $opt{path} // '/health' ) ) );
  return $res;
}

# The error is read defensively: a missing error object must fail the
# expectation, never kill the test.
sub error_attr {
  my ( $err, $attr ) = @_;
  return '' unless ref $err;
  return '' unless $err->$_isa('WWW::Crawl4AI::Error');
  return $err->$attr // '';
}

sub error_message {
  my ( $err ) = @_;
  return '' unless ref $err;
  return $err->$_isa('WWW::Crawl4AI::Error') ? ( $err->message // '' ) : "$err";
}

subtest 'a 200 with an HTML body is an error in the health path' => sub {
  my $err = eval { $client->parse_health_response( response_with($HTML) ); 1 } ? undef : $@;
  isa_ok $err, 'WWW::Crawl4AI::Error', 'the health parse fails';
  is error_attr( $err, 'type' ),        'api', 'classified as api error';
  is error_attr( $err, 'status_code' ), 200,  'the response status is carried';
  like error_message($err), qr/^Crawl4AI HTTP 200: the answer was no JSON \(GET \/health\)$/,
    'the message names status, method and path';
};

subtest 'the other parsers fail on an HTML body' => sub {
  my %case = (
    parse_crawl_response      => [ 'POST', '/crawl' ],
    parse_md_response         => [ 'POST', '/md' ],
    parse_job_status_response => [ 'GET',  '/crawl/job/abc' ],
  );
  for my $parser ( sort keys %case ) {
    my ( $method, $path ) = @{ $case{$parser} };
    my $res = response_with( $HTML, method => $method, path => $path );
    my $err = eval { $client->$parser($res); 1 } ? undef : $@;
    isa_ok $err, 'WWW::Crawl4AI::Error', "$parser fails";
    is error_attr( $err, 'type' ), 'api', "$parser classifies it as api error";
    like error_message($err), qr/^Crawl4AI HTTP 200: the answer was no JSON \(\Q$method $path\E\)$/,
      "$parser names method and path";
  }
};

subtest 'a JSON object is healthy' => sub {
  my $res = response_with( '{"status":"healthy"}', type => 'application/json; charset=utf-8' );
  is $client->parse_health_response($res), 1, 'a JSON object answers 1';
};

subtest 'a JSON scalar is not healthy' => sub {
  my $res = response_with( 'false', type => 'application/json; charset=utf-8' );
  my $verdict = $client->parse_health_response($res);
  is $verdict, 0, 'a JSON scalar answers 0';
  ok !ref $verdict, 'the verdict is a plain 0, not a truthy object';
};

subtest 'an empty body stays allowed' => sub {
  my $res = response_with( '', code => 204, message => 'No Content', type => 'text/plain' );
  my $err = eval { $client->parse_health_response($res); 1 } ? undef : $@;
  is $err, undef, 'an empty body is not an error';
  is $client->parse_health_response($res), 0, 'an empty body answers 0';
};

done_testing;
