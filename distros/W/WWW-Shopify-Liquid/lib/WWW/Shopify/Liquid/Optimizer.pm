#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

package WWW::Shopify::Liquid::Optimizer;
use base 'WWW::Shopify::Liquid::Pipeline';
use WWW::Shopify::Liquid::Security;

use Clone qw(clone);
sub new { 
	my $package = shift;
	my $self = bless {
		clone_hash => 1,
		remove_assignment => 0,
		max_unrolling => 1000,
		max_inclusion_depth => 5,
		timeout => undef,
		inclusion_context => undef,
		inclusion_depth => 0,
		security => WWW::Shopify::Liquid::Security->new,
		conditional_state => [],
		@_ 
	}, $package;
	return $self;
}
sub clone_hash { $_[0]->{clone_hash} = $_[1] if defined $_[1]; return $_[0]->{clone_hash}; }
sub security { $_[0]->{security} = $_[1] if defined $_[1]; return $_[0]->{security}; }
sub max_inclusion_depth { $_[0]->{max_inclusion_depth} = $_[1] if defined $_[1]; return $_[0]->{max_inclusion_depth}; }
sub inclusion_context { $_[0]->{inclusion_context} = $_[1] if defined $_[1]; return $_[0]->{inclusion_context}; }
sub inclusion_depth { $_[0]->{inclusion_depth} = $_[1] if defined $_[1]; return $_[0]->{inclusion_depth}; }
# If we're inside a non-fully-resolved branch, then this is flagged as true; means we can't actually assign things.
sub push_conditional_state {
	my ($self) = @_;
	push(@{$self->{conditional_state}}, { });
}
sub conditional_state { 
	return undef unless int(@{$_[0]->{conditional_state}}) > 0;
	return $_[0]->{conditional_state}->[-1];
}
# Removes the variable from the hash, preventing further optimization, as post unevaluated conditional block, the status of the variable will be uncertain.
sub flag_conditional_uncertainty {
	my ($self, $idarray) = @_;
	my $state = $self->conditional_state;
	return undef unless defined $state;
	my $id = join(".", @$idarray);
	$state->{$id} = $idarray;
}
sub pop_conditional_state {
	my ($self, $hash) = @_;
	my $state = pop(@{$self->{conditional_state}});
	for (values(%$state)) {
		my ($reference, $parent) = $self->variable_reference($hash, $_);
		# If the parent is a hash, remove the element from the hash.
		delete $parent->{$_->[-1]} if ref($parent) eq 'HASH';
	}	
}
# Depending on the type of optimization, you may or may not want to remove assignment or capture blocks.
# In cases where this liquid may be inserted inside other liquid, you may want to set this to 0, as the assignments may affect external objects.
# In cases where the liquid is the only thing being evaluated, with no outside context, it's fine to set this 1.
sub remove_assignment { $_[0]->{remove_assignment} = $_[1] if defined $_[1]; return $_[0]->{remove_assignment}; }
sub timeout { $_[0]->{timeout} = $_[1] if defined $_[1]; return $_[0]->{timeout}; }

sub optimize {
	my ($self, $hash, $ast) = @_;
	return undef unless $ast;
	my $hash_clone = $self->clone_hash && $self->clone_hash == 1 ? clone($hash) : $hash;
	my $result;
	{
		local $SIG{ALRM} = sub { die new WWW::Shopify::Liquid::Exception::Timeout(); };
		alarm $self->timeout if $self->timeout;
		$result = $ast->optimize($self, $hash_clone);
		alarm 0;
	}
	return !ref($result) ? WWW::Shopify::Liquid::Token::Text->new(undef, defined $result ? $result : '') : $result;
}

1;