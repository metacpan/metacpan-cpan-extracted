#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Prepend; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return $_[3] . $_[2]; }

1;