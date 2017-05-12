#!/usr/bin/perl
use strict;
use warnings;

# TODO: Write this.
package WWW::Shopify::Liquid::Filter::ProductImgUrl;
use base 'WWW::Shopify::Liquid::Filter';
sub min_arguments { return 1; }
sub max_arguments { return 1; }
sub operate { 
	my ($self, $hash, $operand, @arguments) = @_;
	return '' unless $operand;
	my $size = $arguments[0];
	$operand =~ s/(\.(jpg|png|jpeg|gif))/_$size$1/i;
	return $operand;
}

1;