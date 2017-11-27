#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::If;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';
use Scalar::Util qw(blessed);

sub min_arguments { return 1; }
sub max_arguments { return 1; }

sub new { 
	my $package = shift;
	my $self = bless {
		line => shift,
		core => shift,
		arguments => shift,
		true_path => undef,
		false_path => undef
	}, $package;
	$self->interpret_inner_tokens(@{$_[0]});
	return $self;
}
sub inner_tags { return qw(elsif else) }
sub subelements { qw(true_path false_path arguments); }

sub interpret_inner_tokens {
	my ($self, @tokens) = @_;
	# Comes in [true_path], [tag, other_path], [tag, other_path], ...
	my $token = shift(@tokens);
	return undef unless $token;
	$self->{true_path} = $token->[0];
	if (int(@tokens) > 0) {
		die new WWW::Shopify::Liquid::Exception::Parser($self, "else cannot be anywhere, except the end tag of an if statement.") if $tokens[0]->[0]->tag eq "else" && int(@tokens) > 1;
		if ($tokens[0]->[0]->tag eq "elsif") {
			$token = shift(@tokens);
			my $arguments = $token->[0]->{arguments};
			$self->{false_path} = WWW::Shopify::Liquid::Tag::If->new($token->[0]->{line}, "if", $arguments, [[$token->[1]], @tokens]);
		}
		else {
			$self->{false_path} = $tokens[0]->[1];
		}
	}
}

sub render {
	my ($self, $renderer, $hash) = @_;
	return $renderer->state->value($self) if $renderer->state && $renderer->state->value($self);	
	my $arguments = $self->render_subelement($renderer, $hash, $self->{arguments});
	my $result;
	eval {
		my $path = $self->{((!$self->inversion && $arguments->[0]) || ($self->inversion && !$arguments->[0])) ? 'true_path' : 'false_path'};
		$result = $path && !$self->is_processed($path) ? $path->render($renderer, $hash) : $path;
	};
	if (my $exp = $@) {
		$exp->value($self->{arguments}, $arguments) if blessed($exp) && $exp->isa('WWW::Shopify::Liquid::Exception::Control::Pause');
		die $exp;
	}
	return defined $result ? $result : '';
}

sub inversion { return 0; }

sub optimize {
	my ($self, $optimizer, $hash) = @_;
	$self->{arguments}->[0] = $self->{arguments}->[0]->optimize($optimizer, $hash) if !$self->is_processed($self->{arguments}->[0]);
	if ($self->is_processed($self->{arguments}->[0])) {
		my $path = $self->{((!$self->inversion && $self->{arguments}->[0]) || ($self->inversion && !$self->{arguments}->[0])) ? 'true_path' : 'false_path'};
		return $self->is_processed($path) ? $path : $path->optimize($optimizer, $hash);
	}
	if (!$self->is_processed($self->{false_path})) {
		$optimizer->push_conditional_state;
		$self->{false_path} = $self->{false_path}->optimize($optimizer, $hash);
		$optimizer->pop_conditional_state($hash);
	}
	if (!$self->is_processed($self->{true_path})) {
		$optimizer->push_conditional_state;
		$self->{true_path} = $self->{true_path}->optimize($optimizer, $hash);
		$optimizer->pop_conditional_state($hash);
	}
	return $self;
}

1;