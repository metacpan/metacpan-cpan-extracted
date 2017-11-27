#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Encode;
use base 'WWW::Shopify::Liquid::Filter';
use Encode;
sub min_arguments { 1; }
sub operate { 
	my ($self, $hash, $operand, $encoding) = @_;
	return encode($encoding, $operand);
}

1;