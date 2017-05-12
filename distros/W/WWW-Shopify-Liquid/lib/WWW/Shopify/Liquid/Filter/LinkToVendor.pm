#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::LinkToVendor;
use base 'WWW::Shopify::Liquid::Filter';
sub operate { return $_[1]->{product} ? "<a href='/collections/vendors?q=" . uri_escape($_[1]->{product}->{vendor}) . "'>" . $_[3] . "</a>" : $_[3]; }

1;