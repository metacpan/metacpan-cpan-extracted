#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::LinkToType; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return $_[1]->{product} ? "<a href='/collections/types?q=" . uri_escape($_[1]->{product}->{type}) . "'>" . $_[3] . "</a>" : $_[3]; }

1;