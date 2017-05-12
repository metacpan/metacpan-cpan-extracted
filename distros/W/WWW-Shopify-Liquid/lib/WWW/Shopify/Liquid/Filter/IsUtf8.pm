#!/usr/bin/perl
use strict;
use warnings;
use utf8;

package WWW::Shopify::Liquid::Filter::IsUtf8;
use base 'WWW::Shopify::Liquid::Filter';

sub min_arguments { return 0; }
sub max_arguments { return 0; }
sub operate { 
	my ($self, $hash, $operand, @arguments) = @_;
	return utf8::is_utf8($operand);
}

1;