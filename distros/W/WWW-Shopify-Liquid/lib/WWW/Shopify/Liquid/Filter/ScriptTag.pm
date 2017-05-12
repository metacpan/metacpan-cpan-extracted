#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::ScriptTag; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return "<script type='text/javascript' src='" . $_[2] . "'></script>"; }

1;