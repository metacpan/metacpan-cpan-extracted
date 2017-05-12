#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Split;
use base 'WWW::Shopify::Liquid::Filter';
use Devel::StackTrace;

sub operate { return [split($_[3], $_[2])]; }

1;