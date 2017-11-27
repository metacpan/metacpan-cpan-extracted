#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Dialect::Shopify::Filter::Handleize;
use base 'WWW::Shopify::Liquid::Filter';
use Text::Unaccent::PurePerl;


sub operate {  
	my $str = $_[2]; $str = '' unless defined $str;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	$str =~ s/\s+/-/g;
	$str =~ s/[^\w-]+//g;
	return lc(unac_string($str));
}

1;