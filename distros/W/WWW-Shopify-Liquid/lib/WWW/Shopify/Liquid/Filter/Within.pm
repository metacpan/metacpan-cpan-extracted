#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Within;
use base 'WWW::Shopify::Liquid::Filter';
 
sub min_arguments { return 1; }
sub max_arguments { return 1; }
sub operate { 
	my ($self, $hash, $operand, $collection) = @_;
	return $operand unless $collection;
	return "/collections/" . $collection->{handle} . $operand;
}

1;