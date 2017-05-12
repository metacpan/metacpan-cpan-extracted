#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Ceil; use base 'WWW::Shopify::Liquid::Filter';
use POSIX qw(ceil);
sub min_arguments { return 0; }
sub max_arguments { return 0; }
sub operate { 
	my ($self, $hash, $operand, @arguments) = @_;
	return ceil($operand);
}

1;