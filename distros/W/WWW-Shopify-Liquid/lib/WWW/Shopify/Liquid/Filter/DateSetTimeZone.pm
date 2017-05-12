#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::DateSetTimeZone;
use base 'WWW::Shopify::Liquid::Filter';

sub min_arguments { return 1; }
sub max_arguments { return 1; }
sub operate { 
	my ($self, $hash, $operand, @arguments) = @_;
	my ($timezone) = @arguments;
	return undef unless ref($operand) && ref($operand) eq "DateTime";
	return $operand->clone->set_time_zone($timezone);
}

1;
