#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Checkout::DiscountCode;
use parent 'WWW::Shopify::Model::Order::DiscountCode';

1;