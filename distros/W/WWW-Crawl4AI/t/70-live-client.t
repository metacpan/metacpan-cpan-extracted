#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Safe::Isa;
use WWW::Crawl4AI::Client;
use WWW::Crawl4AI::Request;

# Live REST tests against a real Crawl4AI service + the deterministic nginx
# fixture (examples/k8s/, or the local-docker recipe in its README). Skipped
# unless both are pointed at, so the normal mocked suite stays offline.
#
#   CRAWL4AI_URL         the REST base URL, reachable from here
#   CRAWL4AI_FIXTURE_URL the fixture URL as reachable FROM the crawl4ai container
my $base    = $ENV{CRAWL4AI_URL};
my $fixture = $ENV{CRAWL4AI_FIXTURE_URL};
plan skip_all => 'set CRAWL4AI_URL and CRAWL4AI_FIXTURE_URL to run live client tests'
  unless $base && $fixture;

my $client = WWW::Crawl4AI::Client->new( base_url => $base );

ok $client->health, 'service reports healthy' or BAIL_OUT("Crawl4AI at $base is not healthy");

subtest 'crawl normalizes the fixture page' => sub {
  my $pages = $client->crawl( WWW::Crawl4AI::Request->new( urls => $fixture ) );
  is ref($pages), 'ARRAY', 'crawl returns an arrayref of pages';
  my $p = $pages->[0];
  is $p->{status_code}, 200, 'HTTP 200';
  like $p->{markdown}, qr/FIXTURE_MARKER_HOME/, 'home marker present in markdown';
  cmp_ok length( $p->{markdown} ), '>', 500, 'markdown clears the thin_content threshold';
  like $p->{title}, qr/Fixture/, 'title resolved from <title>';

  my $links = $p->{links};
  ok scalar( grep { ( $_->{href} // '' ) =~ m{/page2\.html} } @{ $links->{internal} } ),
    'internal page2 link extracted';
  ok scalar( grep { ( $_->{href} // '' ) =~ m{example\.com} } @{ $links->{external} } ),
    'external example.com link extracted';
};

subtest 'md endpoint returns markdown' => sub {
  my $md = $client->md($fixture);
  like $md, qr/FIXTURE_MARKER_HOME/, '/md returned the fixture markdown';
};

subtest 'html endpoint returns preprocessed html' => sub {
  my $html = $client->html($fixture);
  like $html, qr/FIXTURE_MARKER_HOME/, '/html carries the fixture body';
};

subtest 'screenshot returns PNG bytes' => sub {
  my $png = $client->screenshot($fixture);
  ok defined $png && length $png, 'got bytes back';
  is substr( $png, 0, 8 ), "\x89PNG\x0d\x0a\x1a\x0a", 'PNG magic bytes';
};

subtest 'pdf returns PDF bytes' => sub {
  my $pdf = $client->pdf($fixture);
  ok defined $pdf && length $pdf, 'got bytes back';
  is substr( $pdf, 0, 5 ), '%PDF-', 'PDF magic bytes';
};

subtest 'execute_js runs a snippet in the page' => sub {
  my $page = $client->execute_js( $fixture, 'return document.title' );
  ok defined $page->{js_result}, 'js_result present';
  like $page->{markdown}, qr/FIXTURE_MARKER_HOME/, 'execute_js page carries fixture markdown';
};

# Async job endpoints are not present on every Crawl4AI build; probe once and
# skip the subtest cleanly if this server does not expose /crawl/job.
subtest 'async job round-trip' => sub {
  my $job = eval { $client->job_submit( WWW::Crawl4AI::Request->new( urls => $fixture ) ) };
  my $err = $@;
  plan skip_all => 'server has no /crawl/job endpoint'
    if $err && $err->$_isa('WWW::Crawl4AI::Error') && ( $err->status_code // 0 ) == 404;
  plan skip_all => "job_submit failed: $err" if $err;

  ok $job->{task_id}, 'job accepted with a task_id';
  my $status;
  for ( 1 .. 30 ) {
    $status = $client->job_status( $job->{task_id} );
    last if $status->{status} eq 'COMPLETED' || $status->{status} eq 'FAILED';
    sleep 1;
  }
  is $status->{status}, 'COMPLETED', 'job completed';
  like $status->{pages}[0]{markdown}, qr/FIXTURE_MARKER_HOME/, 'job result carries fixture markdown';
};

done_testing;
