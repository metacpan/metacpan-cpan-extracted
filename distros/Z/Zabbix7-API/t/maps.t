use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix7::API;

use lib 't/lib';
use Zabbix7::API::TestUtils;
use Zabbix7::API::Map;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

my $zabber = Zabbix7::API::TestUtils::canonical_login;

ok(my $default = $zabber->fetch('Map', params => { search => { name => 'Local network' } })->[0],
   '... and a map known to exist can be fetched');

isa_ok($default, 'Zabbix7::API::Map',
       '... and that map');

ok($default->exists,
   '... and it returns true to existence tests');

my $map = Zabbix7::API::Map->new(root => $zabber,
                                 data => { name => 'This map brought to you by Zabbix7::API',
                                           width => 800,
                                           height => 600 });

isa_ok($map, 'Zabbix7::API::Map',
       '... and a map created manually');

lives_ok(sub { $map->create }, '... and pushing a new map works');

ok($map->exists, '... and the pushed map returns true to existence tests (id is '.$map->id.')');

$map->data->{width} = 1515;

$map->update;
$map->pull;

is($map->data->{width}, 1515,
   '... and pushing a modified map updates its data on the server');

lives_ok(sub { $map->delete }, '... and deleting a map works');

ok(!$map->exists,
   '... and deleting a map removes it from the server');

eval { $zabber->logout };

done_testing;
