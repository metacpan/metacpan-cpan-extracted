#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Unless;
use base 'WWW::Shopify::Liquid::Tag::If';

sub inversion { return 1; }

1;