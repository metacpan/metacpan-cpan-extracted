#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 17;

use WebService::PagerDuty;
use WebService::PagerDuty::Schedules;
use WebService::PagerDuty::Response;

use Test::LWP::UserAgent;

my $test_api_key = 'jTzyWj10JLv4kW2empqW';
my $pager_duty = WebService::PagerDuty->new(
    subdomain => 'webservice-pagerduty',
    api_key   => $test_api_key,
);

# Make sure that base PD object supports api_key
{
  isa_ok( $pager_duty,        'WebService::PagerDuty', 'Created WebService::PagerDuty object have correct class' );
  is( $pager_duty->subdomain, 'webservice-pagerduty',  'Subdomain in PagerDuty object is correct' );
  is( $pager_duty->api_key,   $test_api_key,           'API Key in PagerDuty object is correct' );
}

# Make sure that Schedules object supports api_key
{
  my $schedules = $pager_duty->schedules();
  isa_ok(
    $schedules,
    'WebService::PagerDuty::Schedules',
    'Created WebService::PagerDuty::Schedules object have correct class'
  );
  ok($schedules->url, 'URL in Schedules object is not empty');
  is($schedules->api_key, $test_api_key, 'api_key in Schedules object is correct');
  is($schedules->user,     undef, 'user in Schedules object is undef');
  is($schedules->password, undef, 'Password in Schedules object is undef');
}

# Make sure that Incidents object supports api_key.
{
  my $incidents = $pager_duty->incidents();
  isa_ok(
    $incidents,
    'WebService::PagerDuty::Incidents',
    'Created WebService::PagerDuty::Incidents object have correct class'
  );
  ok($incidents->url, 'URL in Incidents object is not empty');
  is($incidents->api_key, $test_api_key, 'api_key in Incidents object is correct');
  is($incidents->user,     undef, 'user in Incidents object is undef');
  is($incidents->password, undef, 'Password in Incidents object is undef');
}

# Make sure that Request get() method supports api_key
{
  my $url = URI->new( 'https://webservice-pagerduty.pagerduty.com/api/v1/schedules/POEOPE/entries' );

  my $test_ua = Test::LWP::UserAgent->new();

  my $test_response = HTTP::Response->new(
    '200',
    'OK',
    [ 'Content-Type' => 'application/json' ],
    '{"total":1,"entries":[{"start":"2013-04-25T16:17:48-07:00","end":"2013-04-26T00:00:00-07:00","user":{"id":"PTY9Z3I","name":"Gimp Gimpson","email":"gimpy@gimpysoft.com","color":"purple"}}]}'
  );

  $test_ua->map_response( $url->host, $test_response );

  my $pd_response = WebService::PagerDuty::Request->new( agent => $test_ua )->get_data(
    url     => $url,
    api_key => $test_api_key,
  );

  my $request_made = Test::LWP::UserAgent->last_http_request_sent;

  cmp_ok(
    $request_made->header('Authorization'),
    'eq',
    "Token token=$test_api_key",
    'Request added correct Authorization header'
  );

  ok(! defined($request_made->headers->authorization_basic),'No basic auth was set');

  cmp_ok($pd_response->entries->[0]{user}{name},'eq','Gimp Gimpson','Response was decoded correctly.');
}

# Make sure that basic auth and api_key are mutually exclusive.
{
  throws_ok(
    sub {
      WebService::PagerDuty::Request->new->get_data(
        api_key  => $test_api_key,
        user     => 'me',
        password => 'mypass',
        url      => 'http://example.com',
      );
    },
    qr{mutually exclusive}i,
    'un/pw and api_key are mutually exclusive in Request',
  );
}
