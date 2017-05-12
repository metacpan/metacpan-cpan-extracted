#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Minus;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return '-'; }
sub priority { return 9; }
sub operate {
	$_[3] = $_[3]->epoch if ($_[3] && ref($_[3]) && ref($_[3]) eq 'DateTime');
	$_[4] = $_[4]->epoch if ($_[4] && ref($_[4]) && ref($_[4]) eq 'DateTime');
	
	return $_[0]->ensure_numerical($_[3]) - $_[0]->ensure_numerical($_[4]); }

1;