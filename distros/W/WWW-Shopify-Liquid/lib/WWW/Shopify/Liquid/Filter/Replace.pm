#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Replace;
use base 'WWW::Shopify::Liquid::Filter';

sub min_arguments { return 2; }
sub max_arguments { return 2; }

sub operate { my $str = $_[2]; $str =~ s/$_[3]/$_[4]/g; return $str; }

1;