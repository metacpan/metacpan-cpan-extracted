#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::DateParse;
use base 'WWW::Shopify::Liquid::Filter';
use Date::Parse;
use DateTime::Format::Strptime;

sub min_arguments { return 0; }
sub max_arguments { return 1; }
sub operate { 
	my ($self, $hash, $operand, $pattern) = @_;
	if ($pattern) {
		my $strp = DateTime::Format::Strptime->new(pattern => $pattern);
		return $strp->parse_datetime($operand);
	}
	my $result = str2time($operand, "UTC");
	return undef unless $result;
	return DateTime->from_epoch( epoch => $result, time_zone => "floating" );
}

1;