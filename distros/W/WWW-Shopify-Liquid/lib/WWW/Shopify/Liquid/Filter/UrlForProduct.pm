#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::UrlForProduct; use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 1; }
sub operate { my $str = $_[2]; $str =~ s/\s/-/g; return "/products/" . lc($str); }


1;