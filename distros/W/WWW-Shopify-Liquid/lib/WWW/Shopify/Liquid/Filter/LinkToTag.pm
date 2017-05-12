#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::LinkToTag; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return $_[1]->{collection} ? "<a href='" . $_[1]->{url} . "/" . $_[4] . "'>" . $_[3] . "</a>" : $_[3]; }

1;