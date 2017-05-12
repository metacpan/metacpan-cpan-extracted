#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Truncatewords; use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 1; }
sub min_arguments { return 1; }
sub operate { my @words = split(/\s+/, $_[2]); return join(" ", @words[0..(int($_[3])-1)]); }

1;