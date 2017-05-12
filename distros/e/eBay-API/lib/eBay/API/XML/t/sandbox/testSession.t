#! /usr/bin/perl -w
use strict;
use warnings;

use Test::More qw (no_plan);
use Data::Dumper;

use_ok('eBay::API::XML::Session');
can_ok('eBay::API::XML::Session', ('new'));
$ENV{EBAY_API_AUTH_TOKEN} = 'TESTVALUE';
eBay::BaseApi::enableParameterChecks(0);
my $api = eBay::API::XML::Session->new('yo', 'mama');
is($api, undef, "Bad arguments to Session->new()");
$api = new eBay::API::XML::Session({ 'foo' => 'foo' } );
isnt($api, undef, "Correct args to Session->new()");
can_ok($api, ('getError'));
is($api->getError(), undef, "No errors after instantiation.");
# test some of the logging framework
can_ok($api, ('testLogEntry')); 
my $rc = $api->testLogEntry("Test testLogEntry().");
is($rc, 1, "API::testLogEntry() handles test log message");
# is API::dumpObject inherited ok?
can_ok($api, ('dumpObject'));
$rc = $api->dumpObject();
is($rc, 1, "API::dumpObject dumps self.");
can_ok($api, ('getLogFileHandle'));
is($api->getLogFileHandle(), "*main::STDERR", "Get default log file handle");
can_ok($api, ('setLogFileHandle'));
can_ok($api, ('setLogSubHandle'));

use_ok('eBay::API::XML::Call::GeteBayOfficialTime');
my $call = new eBay::API::XML::Call::GeteBayOfficialTime;
#$api->addRequest(1);
$api->addRequest($call);
my $call2 = new eBay::API::XML::Call::GeteBayOfficialTime;
$call2->setUserName('rlbunau');
$call2->setUserPassword('password');
$api->addRequest($call2);
#$api->setSequentialExecution(1);
#$api->setTimeout(0);
my $results = $api->execute();

my $i = 0;
foreach (@$results) {
  #print $_->getResponseRawXml() . "\n";
  #print Dumper($_);
  is($_->getResponseAck(), 'Success', 'Successful response received.');
  $i++;
}
is($i, 2, "Got both requests back.");
