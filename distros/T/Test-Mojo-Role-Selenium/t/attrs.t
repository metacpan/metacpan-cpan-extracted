use Mojo::Base -strict;
use Test::Mojo::WithRoles 'Selenium';
use Test::More;

use Mojolicious::Lite;
get '/' => sub { shift->render(text => 'dummy') };

$ENV{MOJO_SELENIUM_DRIVER} = mock_driver();
my $t = Test::Mojo::WithRoles->new;

ok $t->isa('Test::Mojo'),                  'isa';
ok $t->does('Test::Mojo::Role::Selenium'), 'does';

isa_ok($t->ua, 'Test::Mojo::Role::Selenium::UserAgent');
is $t->ua->ioloop, Mojo::IOLoop->singleton, 'ua ioloop';

isa_ok($t->_live_server, 'Mojo::Server::Daemon');
is $t->_live_server->listen->[0], $t->_live_base, 'listen';

$t = Test::Mojo::WithRoles->new;
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

$t = Test::Mojo::WithRoles->new('MyApp');
ok !$t->app->isa('MyApp'), 'MOJO_SELENIUM_BASE_URL, so no app';

delete $ENV{MOJO_SELENIUM_BASE_URL};
$t = Test::Mojo::WithRoles->new('MyApp');
isa_ok($t->app, 'MyApp');

done_testing;

sub mock_driver {
  return eval <<'HERE' || die $@;
  package Test::Mojo::Role::Selenium::MockDriver;
  sub debug_on {}
  sub default_finder {}
  sub get {}
  sub new {bless {}, 'Test::Mojo::Role::Selenium::MockDriver'}
  $INC{'Test/Mojo/Role/Selenium/MockDriver.pm'} = 'Test::Mojo::Role::Selenium::MockDriver';
HERE
}
