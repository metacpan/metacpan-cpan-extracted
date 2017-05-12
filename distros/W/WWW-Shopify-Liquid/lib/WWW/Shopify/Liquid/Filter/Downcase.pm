#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Downcase; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return lc(defined $_[2] ? $_[2] : ''); }

1;