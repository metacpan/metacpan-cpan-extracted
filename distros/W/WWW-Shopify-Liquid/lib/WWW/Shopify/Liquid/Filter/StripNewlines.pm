#!/usr/bin/perl
use strict;
use warnings;

use HTML::Strip;

package WWW::Shopify::Liquid::Filter::StripNewlines; use base 'WWW::Shopify::Liquid::Filter';
sub operate { my $text = $_[2]; $text =~ s/\n//g; return $text; }

1;