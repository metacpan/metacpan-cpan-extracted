#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Pluck; use base 'WWW::Shopify::Liquid::Filter';
sub min_arguments { 3; }
sub max_arguments { 3; }
sub operate { 
	my ($self, $hash, $operand, @arguments) = @_;
	my ($field, $value, $wantedfield) = @arguments;
	
	return undef unless ref($operand) eq "ARRAY";
	my @items = grep { ref($_) eq "HASH" && defined $_->{$field} && $_->{$field} eq $value } @$operand;
	return undef unless int(@items) > 0 && ref($items[0]) eq "HASH";
	return $items[0]->{$wantedfield}; 
 
}

1;