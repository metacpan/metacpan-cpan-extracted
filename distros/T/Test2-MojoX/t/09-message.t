#!/usr/bin/env perl
use Mojo::Base -strict;
use Test2::API qw(intercept);
use Test2::V0 -target => 'Test2::MojoX';
use Test2::Tools::Tester qw(facets);

use Mojolicious::Lite;
websocket '/' => sub {
  my $c = shift;
  $c->tx->max_websocket_size(65538)->with_compression;
  $c->on(binary => sub { shift->send({binary => shift}) });
  $c->on(text   => sub { shift->send('text: ' . shift) });
};

my $t = Test2::MojoX->new;
my $assert_facets;

## websocket_ok
$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->status_is(101)->send_ok('hello')
    ->message_ok->message_is('text: hello')->finish_ok(1000)->finished_ok(1000);
};
is @$assert_facets, 7;
is $assert_facets->[0]->details, 'WebSocket handshake with /';
ok $assert_facets->[0]->pass;
is $assert_facets->[1]->details, '101 Switching Protocols';
ok $assert_facets->[1]->pass;
is $assert_facets->[2]->details, 'send message';
ok $assert_facets->[2]->pass;
is $assert_facets->[3]->details, 'message received';
ok $assert_facets->[3]->pass;
is $assert_facets->[4]->details, 'exact match for message';
ok $assert_facets->[4]->pass;
is $assert_facets->[5]->details, 'closed WebSocket';
ok $assert_facets->[5]->pass;
is $assert_facets->[6]->details, 'WebSocket closed with out 1000';
ok $assert_facets->[6]->pass;

## failed websocket_ok
$assert_facets = facets assert => intercept {
  $t->websocket_ok('/404');
};
is @$assert_facets, 1;
is $assert_facets->[0]->details, 'WebSocket handshake with /404';
ok !$assert_facets->[0]->pass;

## failed send_ok
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->send_ok(0);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'send message';
ok !$assert_facets->[1]->pass;

## failed message_ok
my $mock = mock 'Test2::MojoX' => (override => [_wait => sub {0}]);
$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->send_ok(0)->message_ok;
};
is @$assert_facets, 3;
is $assert_facets->[2]->details, 'message received';
ok !$assert_facets->[2]->pass;
undef $mock;

## failed message_is
$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->send_ok('hello')->message_is('text: bye');
};
is @$assert_facets, 3;
is $assert_facets->[2]->details, 'exact match for message';
ok !$assert_facets->[2]->pass;

## failed finish_ok
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->finish_ok;
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'connection is not WebSocket';
ok !$assert_facets->[1]->pass;

# failed finished_ok
$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->finish_ok->finished_ok(0);
};
is @$assert_facets, 3;
is $assert_facets->[2]->details, 'WebSocket closed with out 0';
ok !$assert_facets->[2]->pass;

done_testing;
