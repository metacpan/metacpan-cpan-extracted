#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Include;
use base 'WWW::Shopify::Liquid::Tag::Free';
use File::Slurp;

sub max_arguments { return 1; }
sub min_arguments { return 1; }

sub verify {
	my ($self) = @_;
}

sub retrieve_include {
	my ($self, $hash, $action, $pipeline, $string) = @_;
	if ($pipeline->inclusion_context && $pipeline->parent) {
		# Inclusion contexts are evaluated from left to right, in order of priority.
		my @inclusion_contexts = $pipeline->inclusion_context && ref($pipeline->inclusion_context) && ref($pipeline->inclusion_context) eq "ARRAY" ? @{$pipeline->inclusion_context} : $pipeline->inclusion_context;
		die new WWW::Shopify::Liquid::Exception([], "Backtracking not allowed in inclusions.") if $string =~ m/\.\./;
		for (@inclusion_contexts) {
			if (ref($_) eq "CODE") {
				return $_->($self, $hash, $action, $pipeline, $string);
			} else {
				my $path = $_ . "/" . $string . ".liquid";
				return ($path, scalar(read_file($path))) if -e $path;
			}
		}
		die new WWW::Shopify::Liquid::Exception([], "Can't find include $string.");
	} elsif ($action eq "render") {
		die new WWW::Shopify::Liquid::Exception::Renderer::Unimplemented($self);
	}
	return $self;
}

sub include_literal { 
	my ($self) = @_;
	my $literal = $self->{arguments}->[0];
	if ($literal && ref($literal) && $literal->isa('WWW::Shopify::Liquid::Operator::With')) {
		$literal = $literal->{arguments}->[0];
	} else {
		$literal = $literal;
	}
	return unless $literal->isa('WWW::Shopify::Liquid::Token::String');
	return $literal->{core};
}

sub process_include {
	my ($self, $hash, $action, $pipeline, $string, $path, $text, $argument) = @_;
	my $old_context = $pipeline->parent->lexer->file_context;
	$pipeline->parent->lexer->file_context($path);
	$pipeline->parent->parser->file_context($path);
	$pipeline->parent->renderer->file_context($path);
	# If text is already an AST, then we do not parse the text.
	my $ast = ref($text) ? $text : $pipeline->parent->parse_text($text);
	$hash->{$string} = $argument if defined $argument;
	if ($action eq "optimize") {
		$ast = $pipeline->optimize($hash, $ast);
		$pipeline->parent->lexer->file_context($old_context);
		$pipeline->parent->parser->file_context($old_context);
		$pipeline->parent->renderer->file_context($old_context);
		return $ast;
	} else {
		# Perform no hash cloning.
		my $clone_hash = $pipeline->clone_hash;
		$pipeline->clone_hash(0);
		my ($result) = $pipeline->render($hash, $ast);
		$pipeline->clone_hash($clone_hash);
		$pipeline->parent->lexer->file_context($old_context);
		$pipeline->parent->parser->file_context($old_context);
		$pipeline->parent->renderer->file_context($old_context);
		return $result;
	}
}

sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	die new WWW::Shopify::Liquid::Exception([], "Recursive inclusion probable, greater than depth " . $pipeline->max_inclusion_depth . ". Aborting.")
		if $pipeline->inclusion_depth > $pipeline->max_inclusion_depth;
	return '' unless int(@{$self->{arguments}}) > 0;
	my $result = $self->{arguments}->[0]->$action($pipeline, $hash);
	my ($string, $argument);
	if ($result && ref($result) && $result->isa('WWW::Shopify::Liquid::Operator::With')) {
		$string = $result->{operands}->[0]->$action($pipeline, $hash);
		$argument = $result->{operands}->[1]->$action($pipeline, $hash);
	} else {
		$string = $result;
	}
	return $self if !$self->is_processed($string) || !$self->is_processed($argument);
	my ($path, $text) = $self->retrieve_include($hash, $action, $pipeline, $string, $argument);
	return $self if !$self->is_processed($path);
	my $include_depth = $pipeline->inclusion_depth;
	$pipeline->inclusion_depth($include_depth+1);
	$result = $self->process_include($hash, $action, $pipeline, $string, $path, $text, $argument);
	$pipeline->inclusion_depth($include_depth);
	return $result;
	
}



1;