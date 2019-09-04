#!/usr/bin/env perl
use Mojo::Base -strict;
use Test2::API qw(intercept);
use Test2::V0 -target => 'Test2::MojoX';
use Test2::Tools::Tester qw(facets);

use Mojolicious::Lite;
get '/' => sub {
  shift->render(
    json => {
      scalar => 'value',
      array  => [qw/item1 item2/],
      hash   => {key1 => 'value1', key2 => 'value2'}
    }
  );
};

my $t = Test2::MojoX->new;
my $assert_facets;

## json_has
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_has('/scalar');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'has value for JSON Pointer "/scalar"';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_has('/unknown');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'has value for JSON Pointer "/unknown"';
ok !$assert_facets->[1]->pass;

## json_hasnt
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_hasnt('/unknown');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'has no value for JSON Pointer "/unknown"';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_hasnt('/scalar');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'has no value for JSON Pointer "/scalar"';
ok !$assert_facets->[1]->pass;

## json_is
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_is('/scalar' => 'value');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'exact match for JSON Pointer "/scalar"';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_is(hash {
    field scalar => 'value';
    field array  => array {
      item 'item1';
      item 'item2';
      end;
    };
    field hash => hash {
      field key1 => 'value1';
      field key2 => 'value2';
      end;
    };
    end;
  });
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'exact match for JSON Pointer ""';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_is('/unknown' => 'value');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'exact match for JSON Pointer "/unknown"';
ok !$assert_facets->[1]->pass;

## json_like
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_like('/scalar' => qr/val/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'similar match for JSON Pointer "/scalar"';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_like(hash {
    field scalar => 'value';
    field array  => array {
      all_items match qr/^item/;
    };
  });
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'similar match for JSON Pointer ""';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_like('/scalar' => qr/false/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'similar match for JSON Pointer "/scalar"';
ok !$assert_facets->[1]->pass;

## json_unlike
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_unlike('/scalar' => qr/false/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no similar match for JSON Pointer "/scalar"';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_unlike(hash {
    field scalar => 'false';
    field array  => array {
      all_items match qr/^field/;
    };
  });
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no similar match for JSON Pointer ""';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->json_unlike('/scalar' => qr/value/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no similar match for JSON Pointer "/scalar"';
ok !$assert_facets->[1]->pass;

done_testing;
