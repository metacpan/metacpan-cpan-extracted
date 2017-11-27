#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Sprintf; use base 'WWW::Shopify::Liquid::Filter';
sub min_arguments { return 0; }
sub max_arguments { return undef; }
sub operate { 
	my ($self, $hash, $operand, @arguments) = @_;
	return sprintf($operand, map { defined $_ ? $_ : '' } @arguments);
}

1;