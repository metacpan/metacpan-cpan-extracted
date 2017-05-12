#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Truncate; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return substr($_[2], 0, $_[3]); }

1;