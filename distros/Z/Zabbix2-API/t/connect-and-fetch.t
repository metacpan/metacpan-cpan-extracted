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
use Zabbix2::API::TestUtils;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

use_ok 'Zabbix2::API';

my $zabber = new_ok('Zabbix2::API', [ server => $ENV{ZABBIX_SERVER}, verbosity => $ENV{ZABBIX_VERBOSITY} || 0 ]);

ok($zabber->query(method => 'apiinfo.version'),
   '... and querying Zabbix with a public method succeeds');

eval { $zabber->login(user => 'api', password => 'kweh') };

ok(!$zabber->cookie,
   '... and authenticating with incorrect login/pw fails');

dies_ok(sub { $zabber->query(method => 'item.get',
                             params => { filter => { host => 'Zabbix Server',
                                                     key_ => 'system.uptime' } }) },
        '... and querying Zabbix with no auth cookie fails (assuming no API access is given to the public)');

eval { $zabber->login(user => Zabbix2::API::TestUtils::canonical_username(),
                      password => Zabbix2::API::TestUtils::canonical_password()) };

ok($zabber->cookie,
   '... and authenticating with correct login/pw succeeds');

ok($zabber->query(method => 'item.get',
                  params => { filter => { host => 'Zabbix Server',
                                          key_ => 'system.uptime' } }),
   '... and querying Zabbix with auth cookie succeeds (assuming API access given to this user)');

ok($zabber->fetch_single('Item', params => { itemids => [ 22716 ] }),
   '... and fetch_single does not complain when getting a unique item');

throws_ok(sub { $zabber->fetch_single('Item', params => { itemids => [ 22716, 22717 ] }) },
          qr/Too many results for 'fetch_single': expected 0 or 1, got \d+/,
          '... and fetch_single throws an exception when fetching an item that is not unique');

throws_ok(sub { $zabber->fetch('Foobar', params => {}) },
          qr/Could not load class 'Zabbix2::API::Foobar'/,
          '... and fetch throws an exception when trying to fetch on a module name that cannot be loaded');

eval { $zabber->logout };
ok(!$zabber->cookie,
   '... and logging out removes the cookie from the object');

dies_ok(sub { $zabber->fetch_single('Item', params => { itemids => [ 22716 ] }) },
        q{... and after logging out we are no longer logged in!});

throws_ok(sub { my $fakezabber = Zabbix2::API->new(server => 'http://google.com');
                $fakezabber->ua->timeout(5);
                $fakezabber->login(user => 'api', password => 'kweh') },
          qr/^Could not connect/,
          '... and trying to log to a random URI fails');

done_testing;
