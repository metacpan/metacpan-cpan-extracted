#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Upcase; use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 1; }
sub operate { return uc($_[2]); }

1;