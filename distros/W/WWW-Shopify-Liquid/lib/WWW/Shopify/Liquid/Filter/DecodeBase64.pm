#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::DecodeBase64;
use base 'WWW::Shopify::Liquid::Filter';

use MIME::Base64 qw(decode_base64);

sub operate { 
	my ($self, $hash, $operand) = @_;
	return decode_base64($operand);
}

1;