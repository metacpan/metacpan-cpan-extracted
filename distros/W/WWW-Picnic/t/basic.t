#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
  plan skip_all => "env var TEST_WWW_PICNIC_USER and TEST_WWW_PICNIC_PASS missing" unless $ENV{TEST_WWW_PICNIC_USER} and $ENV{TEST_WWW_PICNIC_PASS};

  use_ok('WWW::Picnic');
}

my $picnic = WWW::Picnic->new(
  user => $ENV{TEST_WWW_PICNIC_USER},
  pass => $ENV{TEST_WWW_PICNIC_PASS},
  $ENV{TEST_WWW_PICNIC_COUNTRY} ? ( country => $ENV{TEST_WWW_PICNIC_COUNTRY} ) : (),
);

isa_ok($picnic, 'WWW::Picnic');
my $picnic_auth = $picnic->picnic_auth;
ok(length($picnic_auth) > 500, "X-Picnic-Auth looks like a token...");

my $user = $picnic->get_user;
is($user->{user_id}, $picnic->_auth_cache->{user_id}, "User id matches auth user id");
is($user->{contact_email}, $ENV{TEST_WWW_PICNIC_USER}, "User contact email matches user login");
for my $key (qw( customer_type feature_toggles firstname lastname )) {
  ok(exists $user->{$key}, 'User has '.$key);
}

my $cart = $picnic->get_cart;
is($cart->{id}, 'shopping_cart', 'Cart request has id shopping_cart');
is($cart->{type}, 'ORDER', 'Cart request has type ORDER');
for my $key (qw( delivery_slots items total_count total_price )) {
  ok(exists $cart->{$key}, 'Cart request has '.$key);
}

my $delivery_slots = $picnic->get_delivery_slots;
ok(exists $delivery_slots->{delivery_slots}, "Delivery slots request has delivery slots");

my $search = $picnic->search('haribo');
is($search->[0]->{id}, 'haribo', 'Search request has id haribo');
ok(exists $search->[0]->{items}, 'Search request has items');

done_testing;
