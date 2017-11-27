#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::NewlineToBr; use base 'WWW::Shopify::Liquid::Filter';
sub operate { 
	my $str = $_[2];
	$str = '' unless defined $str;
	$str =~ s/(\r\n|\n|\r)/<br\/>/g; 
	return $str;
}

1;