#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Request;
use HTTP::Response;
use Safe::Isa;
use WWW::Crawl4AI::Client;

# A redirect must not be followed: the bearer token travels in the
# Authorization header and would reach a foreign host. The agent therefore
# refuses redirects (max_redirect => 0) and every 3xx is an error that names
# status, method and path.

package Stub::UA {
  sub new { bless { res => $_[1], reqs => [] }, $_[0] }
  sub request { push @{ $_[0]{reqs} }, $_[1]; $_[0]{res}->clone }
}

sub client_for {
  my $res = shift;
  my $ua = Stub::UA->new($res);
  return (
    WWW::Crawl4AI::Client->new(
      base_url     => 'http://localhost:11235',
      ua           => $ua,
      api_token    => 'secret-token',
      max_attempts => 1,
      sleep_sub    => sub { },
      retry_backoff => [0],
    ),
    $ua,
  );
}

sub redirect_response {
  my ( $path ) = @_;
  my $res = HTTP::Response->new( 302, 'Found' );
  $res->header( Location => 'http://evil.example/steal' );
  $res->request( HTTP::Request->new( GET => 'http://localhost:11235' . $path ) );
  return $res;
}

# The error text is read defensively: a missing error object must fail the
# expectation, never kill the test.
sub error_message {
  my ( $err ) = @_;
  return '' unless ref $err;
  return $err->$_isa('WWW::Crawl4AI::Error') ? ( $err->message // '' ) : "$err";
}

my $client = WWW::Crawl4AI::Client->new( base_url => 'http://localhost:11235' );
is $client->ua->max_redirect, 0, 'the agent does not follow redirects';

my ( $c, $ua ) = client_for( redirect_response('/crawl/job/abc') );
my $err = eval { $c->job_status('abc'); 1 } ? undef : $@;
isa_ok $err, 'WWW::Crawl4AI::Error', 'a 3xx is an error';
is $err->type,        'api', 'classified as api error';
is $err->status_code, 302,   'status code carried';
like error_message($err), qr/^Crawl4AI HTTP 302: Found \(GET \/crawl\/job\/abc\)$/,
  'the message names status, method and path';

is scalar @{ $ua->{reqs} }, 1, 'no redirect was followed';
is $ua->{reqs}[0]->uri, 'http://localhost:11235/crawl/job/abc', 'the request stayed on the own host';
unlike error_message($err), qr/secret-token/, 'the token is not in the error text';

my ($c2) = client_for( redirect_response('/health') );
my $herr = eval { $c2->parse_health_response( redirect_response('/health') ); 1 } ? undef : $@;
isa_ok $herr, 'WWW::Crawl4AI::Error', 'a 3xx in the health path is an error';
like error_message($herr), qr/^Crawl4AI HTTP 302: Found \(GET \/health\)$/,
  'the health message names status, method and path';

my @warnings;
my $healthy;
{
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  $healthy = $c2->health;
}
is $healthy, 0, 'health stays a boolean 0';
is scalar @warnings, 1, 'health warns once';
like $warnings[0] // '', qr/crawl4ai health check failed: Crawl4AI HTTP 302: Found \(GET \/health\)/,
  'the warning carries the reason';

my ($c3) = client_for( HTTP::Response->new( 302, 'Found' ) );
my $e3 = eval { $c3->parse_job_status_response( HTTP::Response->new( 302, 'Found' ) ); 1 } ? undef : $@;
isa_ok $e3, 'WWW::Crawl4AI::Error', 'a 3xx without a request is an error too';
like error_message($e3), qr/^Crawl4AI HTTP 302: Found \(-/, 'a missing request shows a dash';
unlike error_message($e3), qr/undef/, 'no undef in the message';

# The reason the operator gets is one line: LWP hangs a stack trace behind the
# connect error, that trace is noise on the doctor's stderr.
my $transport = HTTP::Response->new( 500, "Can't connect to 127.0.0.1:9 (Connection refused)" );
$transport->header( 'Client-Warning' => 'Internal response' );
$transport->content(
  "Can't connect to 127.0.0.1:9 (Connection refused)\n\nConnection refused at LWP/Protocol/http.pm line 49.");
my ($c4) = client_for($transport);
my ( @transport_warnings, $transport_health );
{
  local $SIG{__WARN__} = sub { push @transport_warnings, $_[0] };
  $transport_health = $c4->health;
}
is $transport_health, 0, 'a transport error keeps health a boolean 0';
is scalar @transport_warnings, 1, 'the transport error warns once';
like $transport_warnings[0] // '',
  qr/^crawl4ai health check failed: Crawl4AI transport error: Can't connect to 127\.0\.0\.1:9 \(Connection refused\)\n?\z/,
  'the reason is one line, without the stack trace behind it';

done_testing;
