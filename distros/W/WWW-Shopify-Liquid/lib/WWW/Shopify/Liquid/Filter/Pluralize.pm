#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Pluralize; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return int(@{$_[2]}) > 1 ? $_[3] : $_[4]; }

1;