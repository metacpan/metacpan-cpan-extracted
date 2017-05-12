#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Sort; use base 'WWW::Shopify::Liquid::Filter';
use Scalar::Util qw(looks_like_number);
sub operate { 
	my $prop = $_[3];
	return [] unless ref($_[2]) && ref($_[2]) eq 'ARRAY';
	return [sort(@{$_[2]})] if !$prop;
	return [sort {
		defined $a->{$prop} && looks_like_number($a->{$prop}) && defined $b->{$prop} && looks_like_number($b->{$prop}) ? $a->{$prop} <=> $b->{$prop} : $a->{$prop} cmp $b->{$prop};		
	} @{$_[2]}] if $prop;
}

1;