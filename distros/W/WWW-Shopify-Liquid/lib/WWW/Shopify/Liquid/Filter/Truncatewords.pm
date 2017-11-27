#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Truncatewords; use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 2; }
sub min_arguments { return 1; }
sub operate { 
	my ($self, $hash, $operand, $words, $addition) = @_;
	my @words = split(/\s+/, defined $operand ? $operand : "");
	return join(" ", grep { defined $_ } @words[0..(int($words || 0)-1)]) . (defined $addition ? $addition : "");
}

1;