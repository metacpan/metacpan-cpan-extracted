#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Date; use base 'WWW::Shopify::Liquid::Filter';
sub min_arguments { return 1; }
sub max_arguments { return 1; }
sub operate { 
	my ($self, $hash, $operand, @arguments) = @_;
	return '' unless $operand;
	return DateTime->from_epoch( epoch => $operand )->strftime(@arguments) if $operand && !ref($operand);
	return $operand->strftime(@arguments);
}

1;