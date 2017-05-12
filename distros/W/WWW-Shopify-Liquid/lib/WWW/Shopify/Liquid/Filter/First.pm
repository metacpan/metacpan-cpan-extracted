#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::First; use base 'WWW::Shopify::Liquid::Filter';
sub transparent { return 1; }
sub operate { 
	my ($self, $hash, $operand, @arguments) = @_;
	return $operand->[0] if $operand && ref($operand) eq "ARRAY";
	return $operand->{first} if $operand && ref($operand) eq "HASH";
	return undef;
}

1;