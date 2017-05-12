#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Capture;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';
sub min_arguments { return 1; }
sub max_arguments { return 1; }
use Scalar::Util qw(blessed looks_like_number);
sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	my @vars = map { $self->is_processed($_) ? $_ : $_->$action($pipeline, $hash) } @{$self->{arguments}->[0]->{core}};
	return $self if $action eq "optimize" && int(grep { !$self->is_processed($_) } @vars) > 0;
	
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
	
	my $result = $self->{contents}->$action($pipeline, $hash);
	
	return $self unless $self->is_processed($result);
	
	# For now, only do renders.
	if ($action eq "optimize") {
		$pipeline->flag_conditional_uncertainty(\@vars);
		$inner_hash->{$vars[-1]} = $result;
		return undef if $pipeline->remove_assignment && !defined $pipeline->conditional_state;
		return $self;
	}
	if (looks_like_number($vars[-1]) && ref($inner_hash) && ref($inner_hash) eq "ARRAY") {
		$inner_hash->[$vars[-1]] = $result;
	} else {
		$inner_hash->{$vars[-1]} = $result;
	}
	return '';
}

sub verify {
	my ($self) = @_;
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self, "Requires a variable to be the capture target.") unless
		$self->{arguments}->[0]->isa('WWW::Shopify::Liquid::Token::Variable');
}




1;