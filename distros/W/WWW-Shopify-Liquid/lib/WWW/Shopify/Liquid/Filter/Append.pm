#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Append; use base 'WWW::Shopify::Liquid::Filter';
sub operate { 
	return $_[3] if !defined $_[2];
	return $_[2] if !defined $_[3];
	return $_[2] . $_[3];
}

1;