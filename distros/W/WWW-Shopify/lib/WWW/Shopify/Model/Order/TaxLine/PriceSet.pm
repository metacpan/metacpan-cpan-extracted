#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::TaxLine::PriceSet;
use parent "WWW::Shopify::Model::Order::PriceSet";

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
