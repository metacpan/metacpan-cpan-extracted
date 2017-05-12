#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::ThemeUrl; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return "<a href='" . $_[1]->{page}->{url} . "?theme=" . uri_escape($_[4]) . ">" . $_[3] . "</a>"; }

1;