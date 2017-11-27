#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Dialect::Shopify::Filter::T; use base 'WWW::Shopify::Liquid::Filter';
sub operate { die new WWW::Shopify::Liquid::Exception::Renderer::Unimplemented($_[0]); }
sub optimize { return $_[0]; }

1;