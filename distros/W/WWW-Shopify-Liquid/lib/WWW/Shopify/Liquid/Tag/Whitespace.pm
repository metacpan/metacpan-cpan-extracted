#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Whitespace;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';

sub min_arguments { return 0; }
sub max_arguments { return 0; }

sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	
	my $result = $self->{contents}->$action($pipeline, $hash);	
	return $self unless $self->is_processed($result);
	$result =~ s///;
	return $result;
}



1;