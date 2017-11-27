#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Dialect::Web::Tag::JavascriptString;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';

sub min_arguments { 0; }
sub max_arguments { 0; }

sub operate {
	my ($self, $hash, $contents) = @_;
	$contents =~ s/\n/\\n/g;
	$contents =~ s/"/\\"/g;
	$contents =~ s/{/" + /g;
	$contents =~ s/}/ + "/g;
	return "\"$contents\"";
}



1;