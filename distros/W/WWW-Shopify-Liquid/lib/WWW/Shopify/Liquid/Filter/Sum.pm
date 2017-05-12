#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Sum; use base 'WWW::Shopify::Liquid::Filter';
sub transparent { return 1; }
sub max_arguments { return 0; }
use List::Util qw(sum);
sub operate { 
	return sum(@{$_[2]});
}

1;