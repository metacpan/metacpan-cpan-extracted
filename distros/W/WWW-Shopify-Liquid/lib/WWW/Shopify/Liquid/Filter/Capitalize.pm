#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Capitalize; use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 0; }
sub operate { return ucfirst($_[2]); }

1;