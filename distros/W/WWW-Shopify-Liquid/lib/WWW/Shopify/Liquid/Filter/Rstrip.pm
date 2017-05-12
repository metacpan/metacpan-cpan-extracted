#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Rstrip; use base 'WWW::Shopify::Liquid::Filter';
sub transparent { return 1; }
sub operate { 
	my ($self, $hash, $operand) = @_;
	$operand =~ s/\s*$//;
	return $operand;
}

1;