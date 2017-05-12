#! /usr/bin/perl -w
use strict;
use warnings;

use Test::More qw (no_plan);
use Data::Dumper;

use eBay::API::XML::Session;
use eBay::API::XML::Call::GeteBayOfficialTime;

my $api = eBay::API::XML::Session->new();
my $alarmstatus = 0;
my $call = new eBay::API::XML::Call::GeteBayOfficialTime;
$call->setApiUrl('http://www.ebay.comx/');
$api->addRequest($call);

$api->setTimeout(4);
local $SIG{ALRM} = sub { $alarmstatus = 1; };
alarm 8;
my $results = $api->execute();
alarm 0;
is($alarmstatus, 0, "Timeout executed correctly.");
