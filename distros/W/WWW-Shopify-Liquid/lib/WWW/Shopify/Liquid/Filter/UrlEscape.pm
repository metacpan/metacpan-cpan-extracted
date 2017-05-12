#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::UrlEscape;
use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 0; }
use URI::Escape qw(uri_escape);
sub operate { 
	my ($self, $hash, $operand, @arguments) = @_;
	return uri_escape($operand);
}

1;