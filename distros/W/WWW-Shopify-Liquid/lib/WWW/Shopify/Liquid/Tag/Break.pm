#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Break;
use base 'WWW::Shopify::Liquid::Tag::Free';
sub min_arguments { return 1; }
sub process {
	die new WWW::Shopify::Liquid::Exception::Control::Break();
}



1;