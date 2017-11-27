#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Dialect::Shopify::Filter::Money; use base 'WWW::Shopify::Liquid::Filter';
sub operate { 
	return undef unless $_[2];
	my $format = $_[1]->{shop}->{money_format};
	$format = '$ {{ amount }}' unless $format;
	my $amount = sprintf('%.2f', $_[2] / 100.0);
	$format =~ s/\{\{\s*amount\s*\}\}/$amount/;
	return $format;
}
1;