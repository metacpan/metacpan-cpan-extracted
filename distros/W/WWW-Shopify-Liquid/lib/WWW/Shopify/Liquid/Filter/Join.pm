#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Join; use base 'WWW::Shopify::Liquid::Filter';
sub operate { 
	my ($self, $hash, $operand, $argument) = @_;
	return undef unless $operand && ref($operand) eq 'ARRAY';
	return join($argument, @$operand);
}

1;