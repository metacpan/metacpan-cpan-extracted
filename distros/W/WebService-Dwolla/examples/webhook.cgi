#! /usr/bin/perl

use WebService::Dwolla;
use CGI;
use JSON;
use Data::Dumper;

my $api = WebService::Dwolla->new(undef,undef,$redirect_url);

$api->set_api_config_from_file('/usr/local/etc/dwolla_api.conf');

my $q = new CGI->new;

my $signature = $q->html('X-Dwolla-Signature');
my $body      = $q->param('POSTDATA');

my $verified  = $api->verifyWebhookSignature($signature,$body);

my $parsed = my $obj = JSON->new->utf8->decode($body);
print Data::Dumper->Dump([$parsed],'parsed');
