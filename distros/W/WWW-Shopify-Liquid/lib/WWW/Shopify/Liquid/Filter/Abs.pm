#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Abs;
use base 'WWW::Shopify::Liquid::Filter';

sub operate { return abs($_[2]); }

1;