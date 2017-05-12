#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Slice; use base 'WWW::Shopify::Liquid::Filter';

sub operate { 
	my ($self, $hash, $operand, $index, $length) = @_;
	$length = 1 unless defined $length;
	return substr($operand, $index, $length);
}

1;