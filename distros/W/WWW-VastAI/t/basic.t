#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use_ok('WWW::VastAI');
use_ok('WWW::VastAI::Role::HTTP');
use_ok('WWW::VastAI::Role::IO');
use_ok('WWW::VastAI::Role::OperationMap');
use_ok('WWW::VastAI::HTTPRequest');
use_ok('WWW::VastAI::HTTPResponse');
use_ok('WWW::VastAI::LWPIO');

use_ok('WWW::VastAI::API::Offers');
use_ok('WWW::VastAI::API::Instances');
use_ok('WWW::VastAI::API::Templates');
use_ok('WWW::VastAI::API::Volumes');
use_ok('WWW::VastAI::API::SSHKeys');
use_ok('WWW::VastAI::API::APIKeys');
use_ok('WWW::VastAI::API::User');
use_ok('WWW::VastAI::API::EnvVars');
use_ok('WWW::VastAI::API::Invoices');
use_ok('WWW::VastAI::API::Endpoints');
use_ok('WWW::VastAI::API::Workergroups');

use_ok('WWW::VastAI::Offer');
use_ok('WWW::VastAI::Instance');
use_ok('WWW::VastAI::Template');
use_ok('WWW::VastAI::Volume');
use_ok('WWW::VastAI::SSHKey');
use_ok('WWW::VastAI::APIKey');
use_ok('WWW::VastAI::User');
use_ok('WWW::VastAI::Invoice');
use_ok('WWW::VastAI::Endpoint');
use_ok('WWW::VastAI::Workergroup');

my $vast = WWW::VastAI->new(api_key => 'vast-test-key');
isa_ok($vast, 'WWW::VastAI');
is($vast->api_key, 'vast-test-key', 'api key set');
is($vast->base_url, 'https://console.vast.ai/api/v0', 'v0 base url');
is($vast->base_url_v1, 'https://console.vast.ai/api/v1', 'v1 base url');
is($vast->run_url, 'https://run.vast.ai', 'run base url');

done_testing;
