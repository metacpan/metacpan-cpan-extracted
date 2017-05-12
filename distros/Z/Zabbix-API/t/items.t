use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix::API;

use lib 't/lib';
use Zabbix::API::TestUtils;

if ($ENV{ZABBIX_SERVER}) {

    plan tests => 10;

} else {

    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';

}

use_ok('Zabbix::API::Item');

my $zabber = Zabbix::API::TestUtils::canonical_login;

my $items = $zabber->fetch('Item', params => { host => 'Zabbix Server',
                                               search => { key_ => 'system.uptime' } });

is(@{$items}, 1, '... and an item known to exist can be fetched');

my $zabbix_uptime = $items->[0];

isa_ok($zabbix_uptime, 'Zabbix::API::Item',
       '... and that item');

ok($zabbix_uptime->created,
   '... and it returns true to existence tests');

my $host_from_item = $zabbix_uptime->host;

my $host = $zabber->fetch('Host', params => { search => { host => 'Zabbix Server' } })->[0];

is($host_from_item, $host,
   '... and the host accessor accesses the correct host');

is_deeply($host_from_item, $host,
          '... or at least they are identical');

$zabbix_uptime->data->{description} = 'Custom description';

$zabbix_uptime->push;

$zabbix_uptime->pull;

is($zabbix_uptime->data->{description}, 'Custom description',
   '... and updated data can be pushed back to the server');

$zabbix_uptime->data->{description} = 'Host uptime (in sec)';
$zabbix_uptime->push;

my $new_item = Zabbix::API::Item->new(root => $zabber,
                                      data => { key_ => 'system.uptime[minutes]',
                                                description => 'This item brought to you by Zabbix::API',
                                                hostid => $zabbix_uptime->host->data->{hostid} });

isa_ok($new_item, 'Zabbix::API::Item',
       '... and an item created manually');

eval { $new_item->push };

if ($@) { diag "Caught exception: $@" };

ok($new_item->created,
   '... and pushing it to the server creates a new item');

eval { $new_item->delete };

if ($@) { diag "Caught exception: $@" };

ok(!$new_item->created,
   '... and calling its delete method removes it from the server');

eval { $zabber->logout };
