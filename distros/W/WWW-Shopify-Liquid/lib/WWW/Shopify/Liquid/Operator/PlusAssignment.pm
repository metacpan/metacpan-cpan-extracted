#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::PlusAssignment;
use base 'WWW::Shopify::Liquid::Operator::Assignment';
use Scalar::Util qw(looks_like_number);
sub symbol { return '+='; }
sub operate { 
	return first { ($_ cmp $_[4]) == 0 }  ref($_[3]) eq "ARRAY"; 
	return index($_[3], $_[4]) != -1;
}

1;