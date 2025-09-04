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
use Zabbix7::API::Item qw/:item_types :value_types/;
use Zabbix7::API::GraphItem;
use Zabbix7::API::TestUtils;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

use_ok('Zabbix7::API::Graph');

my $zabber = Zabbix7::API::TestUtils::canonical_login;

ok(my $default = $zabber->fetch_single('Graph', params => { search => { name => 'CPU load' },
                                                            filter => { host => 'Zabbix Server' } }),
   '... and a graph known to exist can be fetched');

isa_ok($default, 'Zabbix7::API::Graph',
       '... and that graph');

ok($default->exists,
   '... and it returns true to existence tests');

cmp_deeply($default->graphitems,
           array_each(isa('Zabbix7::API::GraphItem')),
           q{... and it has a bunch of GraphItem objects});

ok(my $url = $default->url,
   q{... and we can get its URL});

my $base_url = $ENV{ZABBIX_SERVER};
$base_url =~ s/api_jsonrpc\.php$/chart2.php/;

like($url, qr/^\Q$base_url\E/,
     q{... and the URL lives on the server});

# no way to check that the URL points to a real graph image: queries
# while not logged in, or queries with bad params return 200 OK and a
# PNG image explaining what went wrong

my $graph = Zabbix7::API::Graph->new(root => $zabber,
                                     data => { name => 'This graph brought to you by Zabbix7::API' });

isa_ok($graph, 'Zabbix7::API::Graph',
       '... and a graph created manually');

my @newitems = @{$zabber->fetch('Item', params => { search => { key_ => 'vm.memory' },
                                                    host => 'Zabbix Server' })};

$graph->add_items(@newitems);

is(@{$graph->graphitems}, 2, '... and the graph can set its items');

lives_ok(sub { $graph->create },
         '... and pushing a new graph works');

ok($graph->exists, '... and the pushed graph returns true to existence tests');

$graph->data->{width} = 1515;

$graph->update;

is($graph->data->{width}, 1515,
   '... and pushing a modified graph updates its data on the server');

$graph->pull;

my $new_item = Zabbix7::API::Item->new(root => $zabber,
                                      data => { key_ => 'system.uptime[minutes]',
                                                name => 'Uptime in minutes',
                                                delay => 300,
                                                type => ITEM_TYPE_ZABBIX_ACTIVE,
                                                value_type => ITEM_VALUE_TYPE_UINT64,
                                                description => 'This item brought to you by Zabbix7::API',
                                                hostid => $graph->data->{hosts}->[0]->{hostid} });
$new_item->create;
$new_item->pull;

$graph->add_items($new_item);

lives_ok(sub { $graph->update }, '... and pushing a graph with a new item works');

lives_ok(sub { $graph->delete }, '... and deleting a graph works');

ok(!$graph->exists,
   '... and deleting a graph removes it from the server');

$new_item->delete;

ok(!$new_item->exists);

eval { $zabber->logout };

done_testing;
