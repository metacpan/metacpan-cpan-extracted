#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Reverse;
use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 0; }
sub operate { 
	my ($self, $hash, $operand) = @_;
	return undef unless (ref($operand) || '') eq 'ARRAY';
	return [reverse(@$operand)];
}

1;
