#!/usr/bin/env perl
use Mojo::Base -strict;
use Test2::API qw(intercept);
use Test2::V0 -target => 'Test2::MojoX';
use Test2::Tools::Tester qw(facets);

use Mojolicious::Lite;
websocket '/' => sub {
  my $c = shift;
  $c->on(json => sub { shift->send({json => shift}) });
};

my $t = Test2::MojoX->new;
my $assert_facets;

## json_message_is
$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->send_ok({json => {test => 23, snowman => '☃'}})
    ->message_ok->json_message_is(hash {
    field test    => 23;
    field snowman => '☃';
    end;
    });
};
is @$assert_facets, 4;
is $assert_facets->[3]->details, 'exact match for JSON Pointer ""';
ok $assert_facets->[3]->pass;

$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->send_ok({json => {test => 23, snowman => '☃'}})
    ->message_ok->json_message_is(hash {
    field test => 23;
    end;
    });
};
is @$assert_facets, 4;
is $assert_facets->[3]->details, 'exact match for JSON Pointer ""';
ok !$assert_facets->[3]->pass;

## json_message_like
$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->send_ok({json => {test => 23, snowman => '☃'}})
    ->message_ok->json_message_like(hash { field test => 23; });
};
is @$assert_facets, 4;
is $assert_facets->[3]->details, 'similar match for JSON Pointer ""';
ok $assert_facets->[3]->pass;

$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->send_ok({json => {test => 23, snowman => '☃'}})
    ->message_ok->json_message_like(hash { field test => 24; });
};
is @$assert_facets, 4;
is $assert_facets->[3]->details, 'similar match for JSON Pointer ""';
ok !$assert_facets->[3]->pass;

## json_message_unlike
$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->send_ok({json => {test => 23, snowman => '☃'}})
    ->message_ok->json_message_unlike(hash { field test => 24; });
};
is @$assert_facets, 4;
is $assert_facets->[3]->details, 'no similar match for JSON Pointer ""';
ok $assert_facets->[3]->pass;

$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->send_ok({json => {test => 23, snowman => '☃'}})
    ->message_ok->json_message_unlike(hash { field test => 23; });
};
is @$assert_facets, 4;
is $assert_facets->[3]->details, 'no similar match for JSON Pointer ""';
ok !$assert_facets->[3]->pass;

## json_message_has
$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->send_ok({json => {test => 23, snowman => '☃'}})
    ->message_ok->json_message_has('/test');
};
is @$assert_facets, 4;
is $assert_facets->[3]->details, 'has value for JSON Pointer "/test"';
ok $assert_facets->[3]->pass;

$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->send_ok({json => {test => 23, snowman => '☃'}})
    ->message_ok->json_message_has('/non-existent');
};
is @$assert_facets, 4;
is $assert_facets->[3]->details, 'has value for JSON Pointer "/non-existent"';
ok !$assert_facets->[3]->pass;

## json_message_hasnt
$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->send_ok({json => {test => 23, snowman => '☃'}})
    ->message_ok->json_message_hasnt('/non-existent');
};
is @$assert_facets, 4;
is $assert_facets->[3]->details, 'has no value for JSON Pointer "/non-existent"';
ok $assert_facets->[3]->pass;

$assert_facets = facets assert => intercept {
  $t->websocket_ok('/')->send_ok({json => {test => 23, snowman => '☃'}})
    ->message_ok->json_message_hasnt('/test');
};
is @$assert_facets, 4;
is $assert_facets->[3]->details, 'has no value for JSON Pointer "/test"';
ok !$assert_facets->[3]->pass;

done_testing;
