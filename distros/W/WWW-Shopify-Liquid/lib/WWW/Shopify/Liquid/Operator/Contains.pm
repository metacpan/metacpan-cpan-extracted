#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Contains;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return 'contains'; }
sub priority { return 11; }
sub operate { 
	my ($self, $hash, $action, $left, $right) = @_;
	return int(grep { $_ eq $right } @$left) > 0 if ref($left) && ref($left) eq 'ARRAY';
	return !defined $_[4] || (defined $_[3] && index($_[3], $_[4]) != -1);
}

1;