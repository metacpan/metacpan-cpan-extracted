#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::In;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return 'in'; }
sub priority { return 11; }

1;