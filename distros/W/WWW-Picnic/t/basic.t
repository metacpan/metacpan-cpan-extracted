#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Live API tests - only run when TEST_WWW_PICNIC_* env vars are set
# These are SEPARATE from the standard PICNIC_* env vars used by the CLI
# to prevent accidental test runs with production credentials

BEGIN {
  plan skip_all => "Set TEST_WWW_PICNIC_USER and TEST_WWW_PICNIC_PASS for live API tests"
    unless $ENV{TEST_WWW_PICNIC_USER} && $ENV{TEST_WWW_PICNIC_PASS};

  use_ok('WWW::Picnic');
}

my $picnic = WWW::Picnic->new(
  user    => $ENV{TEST_WWW_PICNIC_USER},
  pass    => $ENV{TEST_WWW_PICNIC_PASS},
  country => $ENV{TEST_WWW_PICNIC_COUNTRY} // 'de',
);

isa_ok($picnic, 'WWW::Picnic');

subtest 'Login' => sub {
  my $login = $picnic->login;
  isa_ok($login, 'WWW::Picnic::Result::Login');
  ok($login->user_id, "Got user_id from login");

  if ($login->requires_2fa) {
    diag "2FA required - skipping further tests";
    diag "To complete 2FA manually, use the CLI:";
    diag "  TEST_WWW_PICNIC_USER=... TEST_WWW_PICNIC_PASS=... bin/picnic login";
    plan skip_all => "2FA required";
  }

  ok($login->is_authenticated, "Login is authenticated");
};

subtest 'Auth token' => sub {
  my $auth = $picnic->picnic_auth;
  ok(length($auth) > 100, "X-Picnic-Auth looks like a token (length: ".length($auth).")");
};

subtest 'User' => sub {
  my $user = $picnic->get_user;
  isa_ok($user, 'WWW::Picnic::Result::User');
  is($user->user_id, $picnic->_auth_cache->{user_id}, "User ID matches auth cache");
  is($user->contact_email, $ENV{TEST_WWW_PICNIC_USER}, "Contact email matches login");
  ok($user->firstname, "Has firstname: " . ($user->firstname // 'N/A'));
  ok($user->lastname, "Has lastname: " . ($user->lastname // 'N/A'));
  ok($user->customer_type, "Has customer_type: " . ($user->customer_type // 'N/A'));
};

subtest 'Cart' => sub {
  my $cart = $picnic->get_cart;
  isa_ok($cart, 'WWW::Picnic::Result::Cart');
  is($cart->id, 'shopping_cart', 'Cart ID is shopping_cart');
  is($cart->type, 'ORDER', 'Cart type is ORDER');
  ok(defined $cart->total_count, "Has total_count: " . $cart->total_count);
  ok(defined $cart->total_price, "Has total_price: " . $cart->total_price);
};

subtest 'Delivery slots' => sub {
  my $slots = $picnic->get_delivery_slots;
  isa_ok($slots, 'WWW::Picnic::Result::DeliverySlots');
  ok(defined $slots->delivery_slots, "Has delivery_slots");
  my @all = $slots->all_slots;
  diag "Found " . scalar(@all) . " total slots";
  my @available = $slots->available_slots;
  diag "Found " . scalar(@available) . " available slots";
};

subtest 'Search' => sub {
  my $search = $picnic->search('haribo');
  isa_ok($search, 'WWW::Picnic::Result::Search');
  ok($search->first_group_id, "Has first_group_id: " . ($search->first_group_id // 'N/A'));
  my @items = $search->all_items;
  ok(@items > 0, "Found " . scalar(@items) . " search results");
  if (@items) {
    my $first = $items[0];
    isa_ok($first, 'WWW::Picnic::Result::SearchResult');
    ok($first->id, "First result has id: " . ($first->id // 'N/A'));
    ok($first->name, "First result has name: " . ($first->name // 'N/A'));
  }
};

done_testing;
