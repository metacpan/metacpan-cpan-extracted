#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Increment;
use base 'WWW::Shopify::Liquid::Tag::Free';
sub max_arguments { return 1; }
sub min_arguments { return 1; }
sub verify {
	my ($self) = @_;
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self, "Requires variable to increment.") unless
		$self->{arguments}->[0]->isa('WWW::Shopify::Liquid::Token::Variable');
}

use Scalar::Util qw(looks_like_number);
sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	my @vars = map { $self->is_processed($_) ? $_ : $_->$action($pipeline, $hash) } @{$self->{arguments}->[0]->{core}};
	
	my $inner_hash = $hash;
	for (0..$#vars-1) {
		return $self if ref($inner_hash) && ref($inner_hash) eq "HASH" && !exists $inner_hash->{$vars[$_]} && $action eq 'optimize';
		if (looks_like_number($vars[$_]) && ref($inner_hash) && ref($inner_hash) eq "ARRAY") {
			$inner_hash->[$vars[$_]] = {} if !defined $inner_hash->[$vars[$_]];
			$inner_hash = $inner_hash->[$vars[$_]];
		} else {
			$inner_hash->{$vars[$_]} = {} if !exists $inner_hash->{$vars[$_]};
			$inner_hash = $inner_hash->{$vars[$_]};
		}
	}
	if (exists $inner_hash->{$vars[-1]} && looks_like_number($inner_hash->{$vars[-1]})) {
		$inner_hash->{$vars[-1]}++;
	}
	return '';
	
}



1;