#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Dialect::Web::Filter::UrlEscapeParam;
use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 0; }
use URI::Escape qw(uri_escape uri_escape_utf8);

sub operate { 
	my ($self, $hash, $operand, @arguments) = @_;
	return undef unless defined $operand;
	return uri_escape_utf8($operand);
}

1;