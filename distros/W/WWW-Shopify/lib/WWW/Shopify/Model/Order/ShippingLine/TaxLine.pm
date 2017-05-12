#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::ShippingLine::TaxLine;
use parent "WWW::Shopify::Model::Order::TaxLine";

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
