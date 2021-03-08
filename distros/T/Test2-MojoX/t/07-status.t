#!/usr/bin/env perl
use Mojo::Base -strict;
use Test2::API qw(intercept);
use Test2::V0 -target => 'Test2::MojoX';
use Test2::Tools::Tester qw(facets);

use Mojolicious::Lite;

get '/' => sub { shift->reply->not_found };

my $t = Test2::MojoX->new;
my $assert_facets;

## status_is
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->status_is(404)->status_is(number 404)->status_is(match qr/^4/, 'client error');
};
is @$assert_facets, 4;
is $assert_facets->[1]->details, '404 Not Found';
ok $assert_facets->[1]->pass;
like $assert_facets->[2]->details, qr/number/i;
ok $assert_facets->[2]->pass;
is $assert_facets->[3]->details, 'client error';
ok $assert_facets->[3]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->status_is(200)->status_is(string 404)->status_is(match qr/^3/, 'redirected');
};
is @$assert_facets, 4;
is $assert_facets->[1]->details, '200 OK';
ok !$assert_facets->[1]->pass;
like $assert_facets->[2]->details, qr/string/i;
ok $assert_facets->[2]->pass;
is $assert_facets->[3]->details, 'redirected';
ok !$assert_facets->[3]->pass;

## status_isnt
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->status_isnt(200);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'not 200 OK';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->status_isnt(404);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'not 404 Not Found';
ok !$assert_facets->[1]->pass;

done_testing;
