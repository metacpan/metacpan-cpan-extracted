#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::CustomerLoginLink; use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 0; }
sub operate { return '<a href="/customers/login">' . $_[2] .  '</a>'; }

1;