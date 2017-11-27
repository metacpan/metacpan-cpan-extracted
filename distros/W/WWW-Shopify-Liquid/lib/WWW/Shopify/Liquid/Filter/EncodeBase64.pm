#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::EncodeBase64;
use base 'WWW::Shopify::Liquid::Filter';

use MIME::Base64 qw(encode_base64);

sub operate { 
	my ($self, $hash, $operand) = @_;
	return encode_base64($operand);
}

1;