#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::WordWrap;
use base 'WWW::Shopify::Liquid::Filter';

sub max_arguments { 1; }
sub min_arguments { 1; }

sub operate { 
	my ($self, $hash, $text, $max_characters) = @_;
	$text = "" unless defined $text;
	my @parts = ("");
	for (split(/\s/, $text)) {
		push(@parts, "") if ($parts[-1] && length($parts[-1] . " " . $_) > $max_characters);
		if ($parts[-1]) {
			$parts[-1] .= " " . $_;
		} else {
			$parts[-1] = $_;
		}
	}
	return join("\n", @parts);
}

1;