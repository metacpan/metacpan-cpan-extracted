#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Default; 
use base 'WWW::Shopify::Liquid::Filter';
sub operate { 
	my ($self, $hash, $operand, $argument) = @_;
	return defined $operand ? $operand : $argument;
}

1;