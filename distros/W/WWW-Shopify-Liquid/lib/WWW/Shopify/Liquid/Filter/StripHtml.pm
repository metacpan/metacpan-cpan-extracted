#!/usr/bin/perl
use strict;
use warnings;

use HTML::Strip;

package WWW::Shopify::Liquid::Filter::StripHtml; use base 'WWW::Shopify::Liquid::Filter';
sub operate {
	my ($self, $hash, $argument) = @_;
	$argument =~ s/<[^>]+>//g;
	return $argument;
}

1;