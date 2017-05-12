#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::DefaultErrors; use base 'WWW::Shopify::Liquid::Filter';
sub operate { die new WWW::Shopify::Liquid::Exception::Renderer::Unimplemented($_[0]); }

1;