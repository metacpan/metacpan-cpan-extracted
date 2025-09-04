#!perl

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Test::More;
use Test::Exception;
use lib 't/lib';
use Zabbix7::API::TestUtils;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

use_ok 'Zabbix7::API';

my $zabber = new_ok('Zabbix7::API', [ server => $ENV{ZABBIX_SERVER}, verbosity => $ENV{ZABBIX_VERBOSITY} || 0 ]);
Log::Any->get_logger->debug("Initialized Zabbix7::API with server: $ENV{ZABBIX_SERVER}");

ok($zabber->query(method => 'apiinfo.version'), '... and querying Zabbix with a public method succeeds');
Log::Any->get_logger->debug("Queried apiinfo.version successfully");

eval {
    if ($ENV{ZABBIX_API_TOKEN}) {
        $zabber->set_bearer_token($ENV{ZABBIX_API_TOKEN});
    } else {
        $zabber->login(user => 'api', password => 'kweh');
    }
};

ok(!$zabber->token, '... and authenticating with incorrect login/pw or token fails');
Log::Any->get_logger->debug("Failed authentication attempt with user 'api' or invalid token");

dies_ok(sub {
    $zabber->query(method => 'item.get', params => { filter => { host => 'Zabbix server', key_ => 'system.uptime' } })
}, '... and querying Zabbix with no auth fails (assuming no API access is given to the public)');
Log::Any->get_logger->debug("Attempted item.get without authentication, expected to fail");

eval {
    $zabber->set_bearer_token($ENV{ZABBIX_API_TOKEN}) if $ENV{ZABBIX_API_TOKEN};
    $zabber->login(user => Zabbix7::API::TestUtils::canonical_username(),
                   password => Zabbix7::API::TestUtils::canonical_password()) unless $ENV{ZABBIX_API_TOKEN};
};

ok($zabber->token, '... and authenticating with correct login/pw or token succeeds');
Log::Any->get_logger->debug("Authenticated successfully with " . ($ENV{ZABBIX_API_TOKEN} ? "token" : "user: " . Zabbix7::API::TestUtils::canonical_username()));

ok($zabber->query(method => 'item.get', params => { filter => { host => 'Zabbix server', key_ => 'system.uptime' } }),
   '... and querying Zabbix with auth succeeds (assuming API access given to this user)');
Log::Any->get_logger->debug("Queried item.get with authentication successfully");

ok($zabber->fetch_single('Item', params => { itemids => [ 22716 ] }),
   '... and fetch_single does not complain when getting a unique item');
Log::Any->get_logger->debug("Fetched single item with itemid 22716 successfully");

throws_ok(sub { $zabber->fetch_single('Item', params => { itemids => [ 22716, 22717 ] }) },
          qr/Too many results for 'fetch_single': expected 0 or 1, got \d+/,
          '... and fetch_single throws an exception when fetching an item that is not unique');
Log::Any->get_logger->debug("Tested fetch_single with multiple itemids, expected to throw exception");

throws_ok(sub { $zabber->fetch('Foobar', params => {}) },
          qr/Could not load class 'Zabbix7::API::Foobar'/,
          '... and fetch throws an exception when trying to fetch on a module name that cannot be loaded');
Log::Any->get_logger->debug("Tested fetch with invalid class Foobar, expected to throw exception");

eval { $zabber->logout unless $ENV{ZABBIX_API_TOKEN} };
ok(!$zabber->token, '... and logging out removes authentication from the object');
Log::Any->get_logger->debug("Logged out successfully unless using Bearer token");

dies_ok(sub { $zabber->fetch_single('Item', params => { itemids => [ 22716 ] }) },
        '... and after logging out we are no longer authenticated');
Log::Any->get_logger->debug("Attempted fetch_single after logout, expected to fail");

throws_ok(sub {
    my $fakezabber = Zabbix7::API->new(server => 'http://google.com');
    $fakezabber->ua->timeout(5);
    if ($ENV{ZABBIX_API_TOKEN}) {
        $fakezabber->set_bearer_token($ENV{ZABBIX_API_TOKEN});
    } else {
        $fakezabber->login(user => 'api', password => 'kweh');
    }
}, qr/^Could not connect/, '... and trying to authenticate to a random URI fails');
Log::Any->get_logger->debug("Tested authentication with invalid server URL, expected to fail");

done_testing;