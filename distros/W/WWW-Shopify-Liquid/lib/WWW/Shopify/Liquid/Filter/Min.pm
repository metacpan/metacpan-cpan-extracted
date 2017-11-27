#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Min; use base 'WWW::Shopify::Liquid::Filter';
sub transparent { return 1; }
sub max_arguments { return 0; }
use List::Util qw(min);
sub operate { 
	return min(@{$_[2]});
}

1;