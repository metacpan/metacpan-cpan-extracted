#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Join; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return join($_[3], @{$_[2]}); }

1;