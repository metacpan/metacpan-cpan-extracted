#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Dialect::Shopify::Filter::ShopifyAssetUrl; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return "//cdn.shopify.com/s/shopify/" . $_[2]; }

1;