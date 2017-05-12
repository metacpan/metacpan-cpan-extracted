#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::LinkTo; use base 'WWW::Shopify::Liquid::Filter';

sub min_arguments { return 1; }
sub max_arguments { return 1; }

sub operate { 
	my ($self, $hash, $operand, $link) = @_;
	$operand = '' unless defined $operand;
	$link = '' unless defined $link;
	return "<a href='" . $link . "'>" . $operand .  "</a>";
}

1;