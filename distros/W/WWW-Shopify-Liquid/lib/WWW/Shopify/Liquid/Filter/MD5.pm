#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::MD5; use base 'WWW::Shopify::Liquid::Filter';
use Digest::MD5 qw(md5_hex);
use JSON qw(to_json);
sub operate {
	my ($self, $hash, $operand, @arguments) = @_;
	$operand = '' unless defined $operand;
	return md5_hex(to_json($operand, { canonical => 1 })) if ref($operand);
	return md5_hex($operand);
}

1;