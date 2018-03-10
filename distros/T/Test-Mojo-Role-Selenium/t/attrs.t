use lib '.';
use t::Helper;

use Mojolicious::Lite;
get '/' => sub { shift->render(text => 'dummy') };

$ENV{MOJO_SELENIUM_DRIVER} = t::Helper->mock_driver;
my $t = t::Helper->t;

ok $t->isa('Test::Mojo'),                  'isa';
ok $t->does('Test::Mojo::Role::Selenium'), 'does';

isa_ok($t->ua, 'Test::Mojo::Role::Selenium::UserAgent');
is $t->ua->ioloop, Mojo::IOLoop->singleton, 'ua ioloop';

isa_ok($t->_live_server, 'Mojo::Server::Daemon');
is $t->_live_server->listen->[0], $t->_live_base, 'listen';

$t = t::Helper->t;
$ENV{MOJO_SELENIUM_BASE_URL} = 'http://mojolicious.org';
is $t->_live_base, 'http://mojolicious.org', 'custom base';
$t->navigate_ok('/perldoc');
is $t->_live_url, 'http://mojolicious.org/perldoc', 'live url';
ok !$t->{_live_server}, 'server not built';

eval <<'HERE' or die $@;
package MyApp;
use Mojo::Base 'Mojolicious';
1;
HERE

$t = t::Helper->t('MyApp');
ok !$t->app->isa('MyApp'), 'MOJO_SELENIUM_BASE_URL, so no app';

delete $ENV{MOJO_SELENIUM_BASE_URL};
$t = t::Helper->t('MyApp');
isa_ok($t->app, 'MyApp');

done_testing;
