#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::IReplace;
use base 'WWW::Shopify::Liquid::Filter';

sub min_arguments { return 2; }
sub max_arguments { return 2; }
sub name { 'ireplace' }
sub operate { 
	my $str = $_[2];
	return undef unless defined $str;
	$str =~ s/$_[3]/$_[4]/gi;
	return $str; }

1;