#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::StripHtml; use base 'WWW::Shopify::Liquid::Filter';
sub operate {
	my ($self, $hash, $argument) = @_;
	$argument = '' unless defined $argument;
	$argument =~ s/<[^>]+>//g;
	return $argument;
}

1;