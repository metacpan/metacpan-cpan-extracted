#!/usr/bin/env perl
use Mojo::Base -strict;
use Test2::API qw(intercept);
use Test2::V0 -target => 'Test2::MojoX';
use Test2::Tools::Tester qw(facets);

use Mojolicious::Lite;
get '/' => 'index';

my $t = Test2::MojoX->new;
my $assert_facets;

## text_is
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->text_is('#sam' => 'Gamgee');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'exact match for selector "#sam"';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->text_is('#frodo' => 'Baggins')->text_is('#frodo' => undef);
};
is @$assert_facets, 3;
is $assert_facets->[1]->details, 'exact match for selector "#frodo"';
ok !$assert_facets->[1]->pass;
ok $assert_facets->[2]->pass;

## text_isnt
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->text_isnt('#frodo' => 'Baggins');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no match for selector "#frodo"';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->text_isnt('#sam' => 'Gamgee');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no match for selector "#sam"';
ok !$assert_facets->[1]->pass;

## text_like
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->text_like('#sam' => qr/Gamgee/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'similar match for selector "#sam"';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->text_like('#sam' => qr/Baggins/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'similar match for selector "#sam"';
ok !$assert_facets->[1]->pass;

## text_unlike
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->text_unlike('#sam' => qr/Baggins/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no similar match for selector "#sam"';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->text_unlike('#sam' => qr/Gamgee/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no similar match for selector "#sam"';
ok !$assert_facets->[1]->pass;

done_testing;

__DATA__
@@ index.html.epl
<div>
<span id='sam'>Gamgee</span>
</div>
