#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Checkout::TaxLine;
use parent 'WWW::Shopify::Model::Order::TaxLine';

1;