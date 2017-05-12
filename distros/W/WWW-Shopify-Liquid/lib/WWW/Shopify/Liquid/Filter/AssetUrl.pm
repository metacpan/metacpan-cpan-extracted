#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::AssetUrl; use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 0; }
sub operate { die new WWW::Shopify::Liquid::Exception::Renderer::Unimplemented($_[0]); }

1;