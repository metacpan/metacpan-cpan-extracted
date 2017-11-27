#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::RemoveKey;
use base 'WWW::Shopify::Liquid::Tag::Free';
sub min_arguments { return 1; }
sub max_arguments { return 1; } 
sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	my ($ref, $inner_hash, $key) = $pipeline->variable_reference($hash, $self->{arguments}->[0]);
	delete $inner_hash->{$key} if $inner_hash && $key && exists $inner_hash->{$key};
	return $self;
}



1;