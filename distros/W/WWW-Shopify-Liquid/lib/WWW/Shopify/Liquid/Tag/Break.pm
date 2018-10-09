#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Break;
use base 'WWW::Shopify::Liquid::Tag::Free';
sub min_arguments { return 1; }
sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	return $self if $action eq "optimize";
	die new WWW::Shopify::Liquid::Exception::Control::Break();
}



1;