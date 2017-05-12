#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Greater;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return '>'; }
sub priority { return 5; }
sub operate { return ($_[0]->ensure_numerical($_[3]) <=> $_[0]->ensure_numerical($_[4])) == 1; }

1;