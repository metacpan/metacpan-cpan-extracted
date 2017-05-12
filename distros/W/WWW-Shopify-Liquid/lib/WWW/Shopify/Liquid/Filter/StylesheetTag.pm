#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::StylesheetTag; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return '<link rel="stylesheet" href="' . $_[2] . '" type="text/css" />'; }

1;