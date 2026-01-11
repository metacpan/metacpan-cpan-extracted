#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';

BEGIN {
  use_ok('WWW::Picnic');
  use_ok('WWW::Picnic::MockUA');
  use_ok('WWW::Picnic::Result::Login');
  use_ok('WWW::Picnic::Result::User');
  use_ok('WWW::Picnic::Result::Cart');
  use_ok('WWW::Picnic::Result::DeliverySlots');
  use_ok('WWW::Picnic::Result::DeliverySlot');
  use_ok('WWW::Picnic::Result::Search');
  use_ok('WWW::Picnic::Result::SearchResult');
  use_ok('WWW::Picnic::Result::Article');
}

my $fake_user = 'test@example.com';
my $fake_pass = 'testpassword';
my $fake_country = 'de';

# Create mock UA with responses
my $mock_ua = WWW::Picnic::MockUA->new;
$mock_ua->add_response(
  'user/login',
  WWW::Picnic::MockUA::sample_login_response(),
  headers => { 'X-Picnic-Auth' => 'mock-auth-token-12345' },
);
$mock_ua->add_response('api/\d+/user$', WWW::Picnic::MockUA::sample_user_response());
$mock_ua->add_response('cart$', WWW::Picnic::MockUA::sample_cart_response());
$mock_ua->add_response('cart/clear', WWW::Picnic::MockUA::sample_cart_response());
$mock_ua->add_response('cart/delivery_slots', WWW::Picnic::MockUA::sample_delivery_slots_response());
$mock_ua->add_response('search', WWW::Picnic::MockUA::sample_search_response());
$mock_ua->add_response('articles/', WWW::Picnic::MockUA::sample_article_response());
$mock_ua->add_response('cart/add_product', WWW::Picnic::MockUA::sample_cart_response());
$mock_ua->add_response('cart/remove_product', WWW::Picnic::MockUA::sample_cart_response());

my $picnic = WWW::Picnic->new(
  user       => $fake_user,
  pass       => $fake_pass,
  country    => $fake_country,
  http_agent => $mock_ua,
);

subtest 'Basic attributes' => sub {
  isa_ok($picnic, 'WWW::Picnic');
  is($picnic->user, $fake_user, "User is set");
  is($picnic->pass, $fake_pass, "Pass is set");
  is($picnic->country, $fake_country, "Country is set");
  is($picnic->api_version, 15, "Default API version is 15");
  like($picnic->api_endpoint, qr/storefront-prod\.de\.picnicinternational\.com/, "API endpoint is correct");
};

subtest 'Login' => sub {
  my $login = $picnic->login;
  isa_ok($login, 'WWW::Picnic::Result::Login');
  is($login->user_id, 'test-user-123', 'Login user_id');
  ok(!$login->requires_2fa, 'No 2FA required');
  ok($login->is_authenticated, 'Is authenticated');
};

subtest 'User' => sub {
  my $user = $picnic->get_user;
  isa_ok($user, 'WWW::Picnic::Result::User');
  is($user->user_id, 'test-user-123', 'User ID');
  is($user->firstname, 'Max', 'First name');
  is($user->lastname, 'Mustermann', 'Last name');
  is($user->contact_email, 'max@example.com', 'Email');
  is($user->phone, '+49123456789', 'Phone');
  is($user->customer_type, 'REGULAR', 'Customer type');
  is_deeply($user->address, {
    street           => 'Musterstraße',
    house_number     => '42',
    house_number_ext => 'a',
    postcode         => '12345',
    city             => 'Berlin',
  }, 'Address');
  is_deeply($user->feature_toggles, ['feature_a', 'feature_b'], 'Feature toggles');
};

subtest 'Cart' => sub {
  my $cart = $picnic->get_cart;
  isa_ok($cart, 'WWW::Picnic::Result::Cart');
  is($cart->id, 'shopping_cart', 'Cart ID');
  is($cart->type, 'ORDER', 'Cart type');
  is($cart->status, 'OPEN', 'Cart status');
  is($cart->total_count, 3, 'Total count');
  is($cart->total_price, 377, 'Total price');
  is(scalar @{$cart->items}, 2, 'Number of items');
  is($cart->items->[0]{name}, 'Haribo Goldbären', 'First item name');
};

subtest 'Clear cart' => sub {
  my $cart = $picnic->clear_cart;
  isa_ok($cart, 'WWW::Picnic::Result::Cart');
};

subtest 'Delivery slots' => sub {
  my $slots = $picnic->get_delivery_slots;
  isa_ok($slots, 'WWW::Picnic::Result::DeliverySlots');
  is(scalar $slots->all_slots, 2, 'Total slots');
  is(scalar $slots->available_slots, 1, 'Available slots');

  my ($available) = $slots->available_slots;
  isa_ok($available, 'WWW::Picnic::Result::DeliverySlot');
  is($available->slot_id, 'slot-1', 'Slot ID');
  is($available->hub_id, 'hub-berlin-1', 'Hub ID');
  ok($available->is_available, 'Is available');
  is($available->window_start, '2025-01-15T10:00:00Z', 'Window start');
  is($available->window_end, '2025-01-15T12:00:00Z', 'Window end');
};

subtest 'Search' => sub {
  my $search = $picnic->search('haribo');
  isa_ok($search, 'WWW::Picnic::Result::Search');
  is($search->total_count, 2, 'Total results');
  is($search->first_group_id, 'haribo', 'First group ID');

  my @items = $search->all_items;
  is(scalar @items, 2, 'Number of items');
  isa_ok($items[0], 'WWW::Picnic::Result::SearchResult');
  is($items[0]->id, 'product-1', 'First item ID');
  is($items[0]->name, 'Haribo Goldbären 200g', 'First item name');
  is($items[0]->display_price, 129, 'Display price in cents');
  is($items[0]->unit_quantity, '200g', 'Unit quantity');
};

subtest 'Article' => sub {
  my $article = $picnic->get_article('product-1');
  isa_ok($article, 'WWW::Picnic::Result::Article');
  is($article->id, 'product-1', 'Article ID');
  is($article->name, 'Haribo Goldbären 200g', 'Article name');
  like($article->description, qr/Gummibärchen/, 'Description');
  is($article->price, 129, 'Price');
  is($article->original_price, 149, 'Original price');
  is($article->deposit, 0, 'Deposit');
  is($article->unit_quantity, '200g', 'Unit quantity');
  is($article->max_order_quantity, 10, 'Max order quantity');
  ok(!$article->perishable, 'Not perishable');
  is_deeply($article->labels, ['vegetarian'], 'Labels');
};

subtest 'Add to cart' => sub {
  my $cart = $picnic->add_to_cart('product-1', 2);
  isa_ok($cart, 'WWW::Picnic::Result::Cart');
};

subtest 'Remove from cart' => sub {
  my $cart = $picnic->remove_from_cart('product-1', 1);
  isa_ok($cart, 'WWW::Picnic::Result::Cart');
};

subtest 'Result raw access' => sub {
  my $user = $picnic->get_user;
  ok($user->can('raw'), 'Has raw method');
  is(ref $user->raw, 'HASH', 'Raw is hashref');
  is($user->raw->{firstname}, 'Max', 'Can access raw data');
};

done_testing;
