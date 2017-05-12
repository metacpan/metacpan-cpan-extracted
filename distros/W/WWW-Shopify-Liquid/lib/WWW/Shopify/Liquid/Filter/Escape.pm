#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Escape; use base 'WWW::Shopify::Liquid::Filter';
sub operate { my $str = $_[2]; $str =~ s/"/\\"/g; return $str; }

1;