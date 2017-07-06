use lib '.';
use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'Cannot run as root' if $< == 0 or $> == 0;

{
  use Toadfarm -test;
  app->config->{foo} = 1;    # should not override 123 below
  logging {combined => 1, level => 'debug'};
  secrets 'super-secret';
  mount 't::lib::Test' => {'Host' => 'te.st', 'config' => {bar => 123}};
  mount 't::lib::Test' => {'X-Request-Base' => qr{^http:\/\/localhost:1234/yikes}, 'config' => {foo => 123}};
  plugin 't::lib::Plugin' => ['yikes'];
  start ['http://*:5000'], proxy => 1;
}

my $t = Test::Mojo->new;

isa_ok($t->app, 'Toadfarm');
is $t->app->moniker, 'dsl_basic_t', 'moniker';
is_deeply $t->app->secrets, ['super-secret'], 'secrets are set';

$t->get_ok('/')->status_is(404);

$t->get_ok('/', {Host => 'te.st'})->status_is(200)->content_is('http://te.st/test/123');

$t->get_ok('/', {'X-Request-Base' => 'http://localhost:1234/yikes'})->status_is(200)
  ->content_is('http://localhost:1234/yikes/test/123');

$t->get_ok('/info')->status_is(200)->content_is('["yikes"]');

$t->get_ok('/config.json', {'X-Request-Base' => 'http://localhost:1234/yikes'})->status_is(200)->json_is('/foo', 123)
  ->json_has('/plugins', 'inherit toadfarm config')->json_has('/apps')->json_is('/apps/1/Host', 'te.st')
  ->json_is('/hypnotoad/listen', ['http://*:5000'], 'listen')->json_is('/hypnotoad/proxy', 1, 'proxy')
  ->json_is('/log/combined', 1, 'combined')->json_is('/log/level', 'debug');

done_testing;
