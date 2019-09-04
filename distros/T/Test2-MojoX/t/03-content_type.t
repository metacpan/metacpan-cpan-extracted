#!/usr/bin/env perl
use Mojo::Base -strict;
use Test2::API qw(intercept);
use Test2::V0 -target => 'Test2::MojoX';
use Test2::Tools::Tester qw(facets);

use Mojolicious::Lite;

my $t = Test2::MojoX->new;
my $assert_facets;

## content_type_is
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_type_is('text/html;charset=UTF-8');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'Content-Type: text/html;charset=UTF-8';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_type_is('text/html');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'Content-Type: text/html';
ok !$assert_facets->[1]->pass;

## content_type_isnt
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_type_isnt('text/html');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'not Content-Type: text/html';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_type_isnt('text/html;charset=UTF-8');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'not Content-Type: text/html;charset=UTF-8';
ok !$assert_facets->[1]->pass;

## content_type_like
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_type_like(qr[text/html]);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'Content-Type is similar';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_type_like(qr[application/json]);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'Content-Type is similar';
ok !$assert_facets->[1]->pass;

## content_type_unlike
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_type_unlike(qr[application/json]);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'Content-Type is not similar';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_type_unlike(qr[text/html]);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'Content-Type is not similar';
ok !$assert_facets->[1]->pass;

done_testing;
