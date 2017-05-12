#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::With;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return ('with'); }
sub priority { return 11; }
sub operate { return undef; }

1;