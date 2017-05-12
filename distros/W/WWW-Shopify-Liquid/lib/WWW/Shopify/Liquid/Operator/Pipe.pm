#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Pipe;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return '|'; }
sub priority { return 8; }

1;