#!perl -T

use strict;
use warnings;

use Test::More tests => 5;

use WebService::Google::Language;

use constant REFERER => 'http://example.com/';

my $service = WebService::Google::Language->new(REFERER);
is $service->referer, REFERER, q{'referer' is default parameter};

my $agent = 'WebService::Google::Language ' . WebService::Google::Language->VERSION;
is $service->ua->agent, $agent, 'default agent';

$agent = 'my-agent';
$service = WebService::Google::Language->new(REFERER, agent => $agent);
is $service->ua->agent, $agent, 'custom agent';

{
  my $proxy = 'http://proxy.my.place/';
  local $ENV{ftp_proxy} = $proxy;

  $service = WebService::Google::Language->new(REFERER);
  is $service->ua->proxy('ftp'), $proxy, 'respect proxy environment variables (default)';

  $service = WebService::Google::Language->new(REFERER, env_proxy => 0);
  ok !defined $service->ua->proxy('ftp'), 'ignore proxy environment variables';
}
