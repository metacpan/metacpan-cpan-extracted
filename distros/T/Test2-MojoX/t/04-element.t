#!/usr/bin/env perl
use Mojo::Base -strict;
use Test2::API qw(intercept);
use Test2::V0 -target => 'Test2::MojoX';
use Test2::Tools::Tester qw(facets);

use Mojolicious::Lite;
get '/' => 'index';

my $t = Test2::MojoX->new;
my $assert_facets;

## element_count_is
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->element_count_is('ul>li', 2);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'element count for selector "ul>li"';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->element_count_is('div>span', 2);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'element count for selector "div>span"';
ok !$assert_facets->[1]->pass;

## element_exists
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->element_exists('ul>li');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'element for selector "ul>li" exists';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->element_exists('div>span');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'element for selector "div>span" exists';
ok !$assert_facets->[1]->pass;

## element_exists_not
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->element_exists_not('div>span');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no element for selector "div>span"';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->element_exists_not('ul>li');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no element for selector "ul>li"';
ok !$assert_facets->[1]->pass;


done_testing;

__DATA__
@@ index.html.ep
<ul>
<li>Item 1</li>
<li>Item 2</li>
</ul>
