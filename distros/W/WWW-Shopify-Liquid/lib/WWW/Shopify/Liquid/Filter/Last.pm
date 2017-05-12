#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Last; use base 'WWW::Shopify::Liquid::Filter';
sub transparent { return 1; }
sub operate { 
	my ($self, $hash, $operand, @arguments) = @_;
	return $operand->[-1] if $operand && ref($operand) eq "ARRAY";
	return $operand->{last} if $operand && ref($operand) eq "HASH";
	return undef;
}

1;