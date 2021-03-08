#!/usr/bin/env perl
use Mojo::Base -strict;
use Test2::API qw(intercept);
use Test2::V0 -target => 'Test2::MojoX';
use Test2::Tools::Tester qw/facets/;
use Mojolicious::Lite;

get '/' => sub { shift->reply->not_found };

my $t = Test2::MojoX->new;
my $assert_facets;

## content_is
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_is("Oops!\n")
    ->content_is(match qr/o+/i, 'one or more "o"')->content_is(D());
};
is @$assert_facets, 4;
is $assert_facets->[1]->details, 'exact match for content';
ok $assert_facets->[1]->pass;
is $assert_facets->[2]->details, 'one or more "o"';
ok $assert_facets->[2]->pass;
is $assert_facets->[3]->details, 'exact match for content';
ok $assert_facets->[3]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_is('Oops!')
    ->content_is(match qr/^o[^o]/i, 'only one "o"')->content_is(U());
};
is @$assert_facets, 4, 'exactly four tests';
is $assert_facets->[1]->details, 'exact match for content';
ok !$assert_facets->[1]->pass;
is $assert_facets->[2]->details, 'only one "o"';
ok !$assert_facets->[2]->pass;
is $assert_facets->[3]->details, 'exact match for content';
ok !$assert_facets->[3]->pass;

## content_isnt
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_isnt('Oops!');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no match for content';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_isnt("Oops!\n");
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no match for content';
ok !$assert_facets->[1]->pass;

## content_like
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_like(qr/Oops/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'content is similar';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_like(qr/Oops$/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'content is similar';
ok !$assert_facets->[1]->pass;

## content_unlike
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_unlike(qr/Oops$/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'content is not similar';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->content_unlike(qr/Oops/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'content is not similar';
ok !$assert_facets->[1]->pass;

done_testing;

__DATA__
@@ not_found.html.epl
Oops!
