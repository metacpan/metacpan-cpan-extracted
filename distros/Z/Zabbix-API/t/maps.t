use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix::API;

use lib 't/lib';
use Zabbix::API::TestUtils;

if ($ENV{ZABBIX_SERVER}) {

    plan tests => 15;

} else {

    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';

}

use_ok('Zabbix::API::Map');

my $zabber = Zabbix::API::TestUtils::canonical_login;

ok(my $default = $zabber->fetch('Map', params => { search => { name => 'Local network' } })->[0],
   '... and a map known to exist can be fetched');

isa_ok($default, 'Zabbix::API::Map',
       '... and that map');

ok($default->created,
   '... and it returns true to existence tests');

my $map = Zabbix::API::Map->new(root => $zabber,
                                data => { name => 'This map brought to you by Zabbix::API' });

isa_ok($map, 'Zabbix::API::Map',
       '... and a map created manually');

use Zabbix::API::Host;
$map->hosts([ map { { host => $_ } } @{$zabber->fetch('Host', params => { search => { host => 'Zabbix Server' } })}]);

is(@{$map->hosts}, 1, '... and the map can set its hosts');

is((grep { eval { $_->{host}->isa('Zabbix::API::Host') } or diag($@) } @{$map->hosts}), 1,
   '... and they all are Zabbix::API::Host instances');

lives_ok(sub { $map->push }, '... and pushing a new map works');

ok($map->created, '... and the pushed map returns true to existence tests (id is '.$map->id.')');

is(@{$map->hosts}, 1, '... and the hosts survived');

$map->data->{width} = 1515;

$map->push;

is($map->data->{width}, 1515,
   '... and pushing a modified map updates its data on the server');

my $new_host = Zabbix::API::Host->new(root => $zabber,
                                      data => { host => 'Another Server',
                                                ip => '255.255.255.255',
                                                useip => 1,
                                                groups => [ { groupid => 4 } ] });

$map->hosts([{ host => $new_host }]);

lives_ok(sub { $map->push }, '... and pushing a map with a new host works');

ok($new_host->created, '... and the new host is created on the server');

lives_ok(sub { $map->delete }, '... and deleting a map works');

ok(!$map->created,
   '... and deleting a map removes it from the server');

$new_host->delete;

eval { $zabber->logout };
