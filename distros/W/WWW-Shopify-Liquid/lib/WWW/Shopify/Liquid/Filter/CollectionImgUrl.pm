#!/usr/bin/perl
use strict;
use warnings;

# TODO: Write this.
package WWW::Shopify::Liquid::Filter::CollectionImgUrl;
use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 1; }
sub operate { return '<a href="/customers/login">' . $_[2] .  '</a>'; }

1;