#!/usr/bin/perl
use strict;
use warnings;

use WWW::Shopify::Liquid::Tag;

package WWW::Shopify::Liquid::Tag::Assign;
use base 'WWW::Shopify::Liquid::Tag::Free';
use Scalar::Util qw(looks_like_number);
sub min_arguments { return 1; }
sub max_arguments { return 1; }
sub verify {
	my ($self) = @_;
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self, "Requires assignment operator to be the first thing in an assign tag.") unless
		$self->{arguments}->[0]->isa('WWW::Shopify::Liquid::Operator::Assignment');
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($self, "Requires a literal referring to a variable for what you're assigning to.") unless
		$self->{arguments}->[0]->{operands}->[0]->isa('WWW::Shopify::Liquid::Token::Variable');
}
sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	my @vars = map { $self->is_processed($_) ? $_ : $_->$action($pipeline, $hash) } @{$self->{arguments}->[0]->{operands}->[0]->{core}};
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
	
	
	my $result = $self->{arguments}->[0]->{operands}->[1];
	# For now, only do renders.
	if ($action eq "optimize") {
		if (exists $inner_hash->{$vars[-1]}) {
			my $value = delete $inner_hash->{$vars[-1]};
			$result = $result->$action($pipeline, $hash) if !$self->is_processed($result);
			$inner_hash->{$vars[-1]} = $result if $self->is_processed($result);
		} else {
			$result = $result->$action($pipeline, $hash) if !$self->is_processed($result);
		}
		$self->{arguments}->[0]->{operands}->[1] = $result if $self->is_processed($result);
		# If we run across something that should be assigned, we must delete it in the hash to preserve uncertainty.
		# OK, no. We still return ourselves, but we do a bit of a deeper analysis. If the assignment is out the in the open, we assign.
		# If the assignment is contingent upon a conditional, (i.e. inside something that isn't fully resolved). Then we delete it.
		$pipeline->flag_conditional_uncertainty(\@vars);
		$inner_hash->{$vars[-1]} = $result if $self->is_processed($result);
		return undef if $pipeline->remove_assignment && !defined $pipeline->conditional_state;
		return $self;
	} else {
		$result = $result->$action($pipeline, $hash) if !$self->is_processed($result);
	}
	return $self unless $self->is_processed($result);
	
	my $assignment = $self->{arguments}->[0];
	if (looks_like_number($vars[-1]) && ref($inner_hash) && ref($inner_hash) eq "ARRAY") {
		if ($assignment->isa('WWW::Shopify::Liquid::Operator::PlusAssignment')) {
			$inner_hash->[$vars[-1]] += ($result || 0);
		} elsif ($assignment->isa('WWW::Shopify::Liquid::Operator::MinusAssignment')) {
			$inner_hash->[$vars[-1]] -= ($result || 0);
		} elsif ($assignment->isa('WWW::Shopify::Liquid::Operator::MultiplyAssignment')) {
			$inner_hash->[$vars[-1]] *= ($result || 0);
		} elsif ($assignment->isa('WWW::Shopify::Liquid::Operator::DivideAssignment')) {
			$inner_hash->[$vars[-1]] /= $result;
		} else {
			$inner_hash->[$vars[-1]] = $result;
		}
	} else {
		if ($assignment->isa('WWW::Shopify::Liquid::Operator::PlusAssignment')) {
			$inner_hash->{$vars[-1]} += ($result || 0);
		} elsif ($assignment->isa('WWW::Shopify::Liquid::Operator::MinusAssignment')) {
			$inner_hash->{$vars[-1]} -= ($result || 0);
		} elsif ($assignment->isa('WWW::Shopify::Liquid::Operator::MultiplyAssignment')) {
			$inner_hash->{$vars[-1]} *= ($result || 0);
		} elsif ($assignment->isa('WWW::Shopify::Liquid::Operator::DivideAssignment')) {
			$inner_hash->{$vars[-1]} /= $result;
		} else {
			$inner_hash->{$vars[-1]} = $result;
		}
	}
	return '';
}



1;