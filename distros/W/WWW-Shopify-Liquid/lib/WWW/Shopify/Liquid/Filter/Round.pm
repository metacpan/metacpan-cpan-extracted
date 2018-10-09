#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Round; use base 'WWW::Shopify::Liquid::Filter';

use Scalar::Util qw(looks_like_number);
use Math::Round qw(nearest);

sub min_arguments { return 0; }
sub max_arguments { return 1; }
sub operate { 
	my ($self, $hash, $operand, $decimals) = @_;
	$decimals = 0 unless $decimals && looks_like_number($decimals) && $decimals >= 0;
	return nearest(1 * (10**-$decimals), $operand);
}

1;