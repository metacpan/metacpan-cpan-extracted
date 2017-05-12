#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Within;
use base 'WWW::Shopify::Liquid::Filter';
 
sub min_arguments { return 1; }
sub max_arguments { return 1; }
sub operate { return "/collections/" . $_[3]->{handle} . $_[2]; }

1;