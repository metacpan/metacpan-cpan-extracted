use lib '.';
use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'Cannot run as root' if $< == 0 or $> == 0;

{
  use Toadfarm -test;
  app->config->{foo} = 123;
  logging {combined => 1, level => 'debug'};
  mount 't::lib::Test';
  plugin 't::lib::Plugin' => app->config;
  start ['http://*:5000'], proxy => 1;
}

my $t = Test::Mojo->new;

isa_ok($t->app, 'Mojolicious::Lite');
is $t->app->moniker, 'Test', 'moniker';
is $t->app->log->level, 'debug', 'log level';
like $t->app->secrets->[0], qr/^\w{32}$/, 'random secrets';
is_deeply $t->app->config->{hypnotoad}{listen}, ['http://*:5000'], 'listen';
is_deeply $t->app->commands->namespaces, [qw( Mojolicious::Command Toadfarm::Command )], 'correct namespaces';

$t->get_ok('/info')->status_is(200)->json_is('/foo', 123);

done_testing;
