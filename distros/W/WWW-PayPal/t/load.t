#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  WWW::PayPal
  WWW::PayPal::Role::HTTP
  WWW::PayPal::Role::OpenAPI
  WWW::PayPal::API::Orders
  WWW::PayPal::API::Payments
  WWW::PayPal::API::Products
  WWW::PayPal::API::Plans
  WWW::PayPal::API::Subscriptions
  WWW::PayPal::Order
  WWW::PayPal::Capture
  WWW::PayPal::Refund
  WWW::PayPal::Product
  WWW::PayPal::Plan
  WWW::PayPal::Subscription
)) {
    use_ok($_);
}

done_testing;
