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

use_ok('Zabbix::API::Graph');

my $zabber = Zabbix::API::TestUtils::canonical_login;

ok(my $default = $zabber->fetch('Graph', params => { search => { name => 'CPU Loads' } })->[0],
   '... and a graph known to exist can be fetched');

isa_ok($default, 'Zabbix::API::Graph',
       '... and that graph');

ok($default->created,
   '... and it returns true to existence tests');

my $graph = Zabbix::API::Graph->new(root => $zabber,
                                    data => { name => 'This graph brought to you by Zabbix::API' });

isa_ok($graph, 'Zabbix::API::Graph',
       '... and a graph created manually');

is(@{$graph->items}, 0, '... and the graph has no items initially');

use Zabbix::API::Item;
my @newitems = map { { item => $_ } } @{$zabber->fetch('Item', params => { search => { key_ => 'vm.memory' },
                                                                           host => 'Zabbix Server' })};

$graph->items(\@newitems);

is(@{$graph->items}, 5, '... and the graph can set its items');

is((grep { eval { $_->{item}->isa('Zabbix::API::Item') } or diag($@) } @{$graph->items}), 5,
   '... and they all are Zabbix::API::Item instances');

lives_ok(sub { $graph->push }, '... and pushing a new graph works');

ok($graph->created, '... and the pushed graph returns true to existence tests');

$graph->data->{width} = 1515;

$graph->push;

is($graph->data->{width}, 1515,
   '... and pushing a modified graph updates its data on the server');

my $new_item = Zabbix::API::Item->new(root => $zabber,
                                      data => { key_ => 'system.uptime[minutes]',
                                                description => 'This item brought to you by Zabbix::API',
                                                hostid => $graph->items->[0]->{item}->data->{hostid} });

push @{$graph->items}, ({ item => $new_item });

lives_ok(sub { $graph->push }, '... and pushing a graph with a new item works');

ok($new_item->created, '... and the new item is created on the server');

lives_ok(sub { $graph->delete }, '... and deleting a graph works');

ok(!$graph->created,
   '... and deleting a graph removes it from the server');

$new_item->delete;

eval { $zabber->logout };
