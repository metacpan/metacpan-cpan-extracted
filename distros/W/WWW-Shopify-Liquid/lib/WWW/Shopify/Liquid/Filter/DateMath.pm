#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::DateMath;
use base 'WWW::Shopify::Liquid::Filter';
# +-, #, <unit>
sub min_arguments { return 2; }
sub max_arguments { return 2; }
sub operate { 
	my ($self, $hash, $operand, @arguments) = @_;
	my ($number, $unit) = @arguments;
	$unit = lc($unit);
	return undef unless ref($operand) && ref($operand) eq "DateTime";
	return $operand unless $unit =~ m/^(days|months|years|weeks|seconds|minutes|hours)$/;
	return $operand->clone->add(
		$unit => $number
	);
}

1;