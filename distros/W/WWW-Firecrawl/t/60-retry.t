#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );

use WWW::Firecrawl;

{
  package Test::StubUA;
  sub new {
    my ( $class, @responses ) = @_;
    return bless { queue => [ @responses ], log => [] }, $class;
  }
  sub request {
    my ( $self, $req ) = @_;
    push @{ $self->{log} }, $req;
    my $next = shift @{ $self->{queue} };
    die "Test::StubUA ran out of scripted responses\n" unless $next;
    return $next;
  }
  sub log { $_[0]->{log} }
}

sub ok_response {
  my $body = encode_json({ success => JSON::MaybeXS::true(), data => { markdown => 'OK' } });
  return HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'application/json' ], $body );
}

sub err_response {
  my ( $code, %headers ) = @_;
  return HTTP::Response->new( $code, 'err',
    [ 'Content-Type' => 'text/plain', %headers ], 'bad' );
}

subtest 'retries 503 503 then succeeds' => sub {
  my $ua = Test::StubUA->new( err_response(503), err_response(503), ok_response() );
  my @slept;
  my $fc = WWW::Firecrawl->new(
    base_url => 'http://x',
    ua => $ua,
    sleep_sub => sub { push @slept, $_[0] },
  );
  my $data = $fc->scrape( url => 'https://x' );
  is $data->{markdown}, 'OK';
  is scalar @{ $ua->log }, 3, 'three attempts';
  is_deeply \@slept, [ 1, 2 ], 'backoff 1s, 2s';
};

subtest 'max_attempts => 1 throws immediately' => sub {
  my $ua = Test::StubUA->new( err_response(503) );
  my $fc = WWW::Firecrawl->new(
    base_url => 'http://x', ua => $ua, max_attempts => 1, sleep_sub => sub { },
  );
  my $e = exception { $fc->scrape( url => 'https://x' ) };
  isa_ok $e, 'WWW::Firecrawl::Error';
  ok $e->is_api;
  is $e->status_code, 503;
  is $e->attempt, 1;
  is scalar @{ $ua->log }, 1;
};

subtest 'Retry-After header overrides backoff' => sub {
  my $ua = Test::StubUA->new(
    err_response( 429, 'Retry-After' => 7 ),
    ok_response(),
  );
  my @slept;
  my $fc = WWW::Firecrawl->new(
    base_url => 'http://x', ua => $ua, sleep_sub => sub { push @slept, $_[0] },
  );
  $fc->scrape( url => 'https://x' );
  is_deeply \@slept, [ 7 ], 'Retry-After honored';
};

subtest 'on_retry callback fires' => sub {
  my $ua = Test::StubUA->new( err_response(502), ok_response() );
  my @calls;
  my $fc = WWW::Firecrawl->new(
    base_url => 'http://x', ua => $ua,
    sleep_sub => sub { },
    on_retry => sub {
      my ( $attempt, $delay, $error ) = @_;
      push @calls, { attempt => $attempt, delay => $delay, type => $error->type };
    },
  );
  $fc->scrape( url => 'https://x' );
  is scalar @calls, 1;
  is $calls[0]{attempt}, 1;
  is $calls[0]{delay}, 1;
  is $calls[0]{type}, 'api';
};

subtest 'non-retryable 4xx does not retry' => sub {
  my $ua = Test::StubUA->new(
    HTTP::Response->new( 400, 'Bad', [ 'Content-Type'=>'application/json' ],
                          encode_json({ error => 'bad url' })),
  );
  my @slept;
  my $fc = WWW::Firecrawl->new(
    base_url => 'http://x', ua => $ua, sleep_sub => sub { push @slept, $_[0] },
  );
  my $e = exception { $fc->scrape( url => 'https://x' ) };
  isa_ok $e, 'WWW::Firecrawl::Error';
  is $e->status_code, 400;
  is scalar @slept, 0;
  is scalar @{ $ua->log }, 1;
};

done_testing;
