use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Test::More;
use Test::Exception;
use Test::Deep;

use Zabbix7::API;

use lib 't/lib';
use Zabbix7::API::TestUtils;
use Zabbix7::API::Item qw/:item_types :value_types/;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

my $zabber = Zabbix7::API::TestUtils::canonical_login;

my $items = $zabber->fetch('Item', params => { host => 'Zabbix Server',
                                               search => { key_ => 'system.uptime' } });

is(@{$items}, 1, '... and an item known to exist can be fetched');

my $zabbix_uptime = $items->[0];

isa_ok($zabbix_uptime, 'Zabbix7::API::Item',
       '... and that item');

ok($zabbix_uptime->exists,
   '... and it returns true to existence tests');

my $historical_data = $zabbix_uptime->history;

cmp_deeply($historical_data,
           array_each({ itemid => $zabbix_uptime->id,
                        clock => re(qr/\d+/),
                        value => ignore(),
                        ns => re(qr/\d+/) }),
           q{... and the history accessor contains historical data});

my $host_from_item = $zabbix_uptime->host;

my $host = $zabber->fetch('Host', params => { search => { host => 'Zabbix Server' } })->[0];

is_deeply($host_from_item, $host,
          '... or at least they are identical');

$zabbix_uptime->data->{description} = 'Custom description';

$zabbix_uptime->update;
$zabbix_uptime->pull;

is($zabbix_uptime->data->{description}, 'Custom description',
   '... and updated data can be pushed back to the server');

$zabbix_uptime->data->{description} = 'Host uptime (in sec)';
$zabbix_uptime->update;

my $new_item = Zabbix7::API::Item->new(root => $zabber,
                                      data => { key_ => 'system.uptime[minutes]',
                                                name => 'Uptime in $1',
                                                delay => 300,
                                                type => ITEM_TYPE_ZABBIX_ACTIVE,
                                                value_type => ITEM_VALUE_TYPE_UINT64,
                                                description => 'This item brought to you by Zabbix7::API',
                                                hostid => $zabbix_uptime->host->data->{hostid} });

isa_ok($new_item, 'Zabbix7::API::Item',
       '... and an item created manually');

eval { $new_item->create };

if ($@) { diag "Caught exception: $@" };

ok($new_item->exists,
   '... and pushing it to the server creates a new item');

is($new_item->expanded_name, 'Uptime in minutes',
   q{... and its name is correctly expanded});

eval { $new_item->delete };

if ($@) { diag "Caught exception: $@" };

ok(!$new_item->exists,
   '... and calling its delete method removes it from the server');

eval { $zabber->logout };

done_testing;
