#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Checkout::ShippingLine;
use parent 'WWW::Shopify::Model::Order::TaxLine';

1;