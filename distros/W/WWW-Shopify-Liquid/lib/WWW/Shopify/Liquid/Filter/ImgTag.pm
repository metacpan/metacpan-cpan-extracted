#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::ImgTag; use base 'WWW::Shopify::Liquid::Filter';
sub operate {
	return "<img src='" . $_[2] .  "' alt='" . $_[3] . "' class='" . join(" ", @_[4..$#_]). "'>" unless !$_[4];
	return "<img src='" . $_[2] .  "' alt='" . $_[3] . "'>" unless !$_[3];
	return "<img src='" . $_[2] .  "'>";
}

1;