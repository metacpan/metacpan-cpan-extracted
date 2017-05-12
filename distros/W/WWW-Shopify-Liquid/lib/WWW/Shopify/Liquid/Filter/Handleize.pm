#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Handleize; use base 'WWW::Shopify::Liquid::Filter';
sub operate {  my $str = $_[2]; $str = '' unless defined $str; $str =~ s/\s+/-/g; $str =~ s/[^\w-]+//g; return lc($str); }

1;