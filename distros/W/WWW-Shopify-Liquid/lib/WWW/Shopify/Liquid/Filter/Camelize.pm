#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Camelize; use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 0; }
sub operate {  my $str = $_[2]; return '' unless defined $str; $str =~ s/-(\w?)/return " " . uc($1);/ge; return $str; }

1;