#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::RemoveFirst; use base 'WWW::Shopify::Liquid::Filter';
sub operate { my $str = $_[2]; $str =~ s/$_[3]//; return $str; }

1;