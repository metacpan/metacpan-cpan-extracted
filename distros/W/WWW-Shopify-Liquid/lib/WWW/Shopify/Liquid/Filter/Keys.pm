#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Keys;
use base 'WWW::Shopify::Liquid::Filter';

sub operate { 
	return undef unless ref($_[2]) && ref($_[2]) eq 'HASH';
	return [keys(%{$_[2]})];
}

1;