use Test::More;
use Test::Exception;

use Zabbix2::API;
use Zabbix2::API::Screen;
use Zabbix2::API::Graph;

use lib 't/lib';
use Zabbix2::API::TestUtils;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

my $zabber = Zabbix2::API::TestUtils::canonical_login;

ok(my $default = $zabber->fetch('Screen', params => { search => { name => 'Zabbix server' } })->[0],
   '... and a screen known to exist can be fetched');

isa_ok($default, 'Zabbix2::API::Screen',
       '... and that screen');

ok($default->exists,
   '... and it returns true to existence tests');

my $screen = Zabbix2::API::Screen->new(root => $zabber,
                                       data => { name => 'This screen brought to you by Zabbix2::API' });

isa_ok($screen, 'Zabbix2::API::Screen',
       '... and a screen created manually');

my $graph = $zabber->fetch_single('Graph', params => { search => { name => 'CPU load' },
                                                       filter => { host => 'Zabbix Server' } });

lives_ok(sub { $screen->set_item_at($graph, 'x' => 0, 'y' => 0) },
         '... and adding screenitems with coordinates works');

is($screen->data->{hsize}, 1,
   '... and adding screenitems with coordinates sets the horizontal screen size');

is($screen->data->{vsize}, 1,
   '... and adding screenitems with coordinates sets the vertical screen size');

lives_ok(sub { $screen->create },
         '... and pushing the screen works');

ok($screen->exists,
   '... and pushing the screen to the server creates a new screen');

is(@{$screen->items}, 1, '... and the screen has set its items');

$screen->data->{name} = 'Custom screen';

$screen->update;
$screen->pull; # ensure the data is refreshed

is($screen->data->{name},
   'Custom screen',
   '... and pushing a modified screen updates its data on the server');

lives_ok(sub { $screen->delete }, '... and deleting a screen works');

ok(!$screen->exists,
   '... and deleting a screen removes it from the server');

eval { $zabber->logout };

done_testing;
