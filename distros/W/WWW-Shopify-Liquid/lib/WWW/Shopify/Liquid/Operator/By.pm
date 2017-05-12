#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::By;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return ('by'); }
sub priority { return 11; }
sub operate { return [$_[3], $_[4]]; }

1;