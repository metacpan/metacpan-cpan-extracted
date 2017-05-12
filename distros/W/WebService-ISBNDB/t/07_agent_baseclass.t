#!/usr/bin/perl

# $Id: 07_agent_baseclass.t 29 2006-10-02 06:12:34Z  $

use strict;

use File::Basename 'dirname';
use Test::More tests => 16;

use WebService::ISBNDB::API;
use WebService::ISBNDB::Agent;

do (dirname $0) . '/util.pl';

# Test adding and removing of protocols. Test that protocol names are
# normalized, and that attempts to remove core protocols fail.
eval { WebService::ISBNDB::Agent->remove_protocol('REST'); };
like($@, '/Cannot remove a core/i', 'Try to remove core protocols');
WebService::ISBNDB::Agent->add_protocol('SOAP', 'Test::SOAP');
is(WebService::ISBNDB::Agent->class_for_protocol('SOAP'), 'Test::SOAP',
   'Adding protocols');
WebService::ISBNDB::Agent->add_protocol('soap', 'Test::SOAP2');
is(WebService::ISBNDB::Agent->class_for_protocol('SOAP'), 'Test::SOAP2',
   'Protocol name normalization for adds');
WebService::ISBNDB::Agent->remove_protocol('SOAP');
is(WebService::ISBNDB::Agent->class_for_protocol('SOAP'), undef,
   'Removing user-defined protocols');

# Test protocol(), which in this class should return an error
eval { WebService::ISBNDB::Agent->protocol; };
like($@, '/has not overridden/i', 'Base-class version of protocol()');

# Start testing agent creation, and agent_args influence.
my $agent = WebService::ISBNDB::Agent->new('REST');
isa_ok($agent, 'WebService::ISBNDB::Agent', 'Agent object');
my $ua = $agent->get_useragent;
isa_ok($ua, 'LWP::UserAgent', 'get_agent return');
like($ua->agent, '/libwww-perl/i', 'LWP::UA instance default ident string');

$agent->set_useragent(undef);
$agent->set_agent_args({ agent => "test/0" });
$ua = $agent->get_useragent;
isa_ok($ua, 'LWP::UserAgent', 'get_agent/LWP::UserAgent instance with args');
is($ua->agent, 'test/0', 'LWP::UA instance pre-set ident string');
undef $agent;

# Test using the methods from WS::I::API
my $api = WebService::ISBNDB::API->new();
$agent = $api->get_agent;
isa_ok($agent, 'WebService::ISBNDB::Agent::REST');
isa_ok($agent->get_useragent, 'LWP::UserAgent');

$agent = WebService::ISBNDB::API->get_default_agent;
is($agent, WebService::ISBNDB::API->get_agent,
   "Default returned on static call");
WebService::ISBNDB::API->set_default_agent(undef);
WebService::ISBNDB::API->set_default_agent_args({ agent => "test/0" });
$agent = WebService::ISBNDB::API->get_default_agent;
isa_ok($agent, 'WebService::ISBNDB::Agent::REST', 'Default-args agent');
isa_ok($agent->get_useragent, 'LWP::UserAgent', 'Default-args agent UA');
is($agent->get_useragent->agent, 'test/0',
  'Ident string set from default args');

exit;
