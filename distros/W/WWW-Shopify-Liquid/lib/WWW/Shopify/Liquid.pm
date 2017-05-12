#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Liquid::Pipeline;
use Scalar::Util qw(weaken blessed looks_like_number);
sub register_tag { }
sub register_operator {
	die new WWW::Shopify::Liquid::Exception("Cannot have a unary operator, that has infix notation.") if $_[1]->arity eq "unary" && $_[1]->fixness eq "infix";
}
sub register_filter { }
sub strict { $_[0]->{strict} = $_[1] if defined $_[1]; return $_[0]->{strict}; }
sub file_context { $_[0]->{file_context} = $_[1] if @_ > 1; return $_[0]->{file_context}; }
sub parent { 
	if (defined $_[1]) {
		$_[0]->{parent} = $_[1];
		weaken($_[0]->{parent});
	}
	return $_[0]->{parent};
}

sub is_processed { 
	return !ref($_[1]) ||
		(ref($_[1]) eq "ARRAY" && int(grep { !$_[0]->is_processed($_) } @{$_[1]}) == 0) ||
		(ref($_[1]) eq "HASH" && int(grep { !$_[0]->is_processed($_[1]->{$_}) } keys(%{$_[1]})) == 0) || 
		(blessed($_[1]) && ref($_[1]) !~ m/^WWW::Shopify::Liquid/ && !$_[1]->isa('WWW::Shopify::Liquid::Element'));
}

# If static is true, we do not create new indices, we return null.
sub variable_reference {
	my ($self, $hash, $indices, $static) = @_;
	my @vars = @$indices;
	my $inner_hash = $hash;
	for (0..$#vars-1) {
		if (looks_like_number($vars[$_]) && ref($inner_hash) && ref($inner_hash) eq "ARRAY") {
			if (!defined $inner_hash->[$vars[$_]]) {
				return () if $static;
				$inner_hash->[$vars[$_]] = {};
			}
			$inner_hash = $inner_hash->[$vars[$_]];
		} else {
			if (!exists $inner_hash->{$vars[$_]}) {
				return () if $static;
				$inner_hash->{$vars[$_]} = {};
			}
			$inner_hash = $inner_hash->{$vars[$_]};
		}
	}
	if (looks_like_number($vars[-1]) && ref($inner_hash) && ref($inner_hash) eq "ARRAY") {
		return (\$inner_hash->[$vars[-1]], $inner_hash) if int(@$inner_hash) > $vars[-1] || !$static;
	} else {
		return (\$inner_hash->{$vars[-1]}, $inner_hash) if exists $inner_hash->{$vars[-1]} || !$static;
	}
	return ();
}

sub make_method_calls { $_[0]->{make_method_calls} = $_[1] if @_ > 1; return $_[0]->{make_method_calls}; }

package WWW::Shopify::Liquid::Element;

sub verify { return 1; }
sub render { 
	my $self = shift;
	my $renderer = shift;
	die new WWW::Shopify::Liquid::Exception(undef, "Cannot render without a valid renderer.") 
		unless $renderer && blessed($renderer) && $renderer->isa('WWW::Shopify::Liquid::Renderer');
	my $return;
	my $exp;
	if ($renderer->{silence_exceptions}) {
		$return = eval { $self->process(@_, "render", $renderer); };
		$exp = $@;
		die $exp if (blessed($exp) && $exp->isa('WWW::Shopify::Liquid::Exception::Control'));
	} else {
		$return = $self->process(@_, "render", $renderer);
	}
	return undef if $exp || !$self->is_processed($return) || !defined $return;
	return $return;
}

sub get_parameter {
	my ($self, $name, @arguments) = @_;
	my ($arg) = grep { ref($_) && ref($_) eq 'HASH' && int(keys(%$_)) == 1 && exists $_->{$name} } @arguments;
	return $arg ? $arg->{$name} : undef;
}

sub optimize {
	my $self = shift;
	my $optimizer = shift;
	die new WWW::Shopify::Liquid::Exception("Cannot optimize without a valid optimizer.") 
		unless $optimizer && blessed($optimizer) && $optimizer->isa('WWW::Shopify::Liquid::Optimizer');
	return $self->process(@_, "optimize", $optimizer);
}
sub process { return $_[0]; }
# Determines whether or not the element is part of the strict subset of liquid that Shopify uses.
sub is_strict { return 0; }

use Scalar::Util qw(looks_like_number blessed);

sub is_processed { return WWW::Shopify::Liquid::Pipeline->is_processed($_[1]); }
sub ensure_numerical { 
	return $_[1] if defined $_[1] && looks_like_number($_[1]); 
	return $_[1] if ref($_[1]) && ref($_[1]) eq "DateTime";
	return 0;
}

package WWW::Shopify::Liquid;
use File::Slurp;
use List::MoreUtils qw(firstidx part);
use Module::Find;

our $VERSION = '0.06';

=head1 NAME

WWW::Shopify::Liquid - Fully featured liquid preprocessor with shopify tags & filters added in.

=cut

=head1 DESCRIPTION

A concise and clear liquid processor. Runs a superset of what Shopify can do. For a strict shopify implementation
see L<Template::Liquid> for one that emulates all the quirks and ridiculousness of the real thing, but without the tags.
(Meaning no actual arithemtic is literal tags without filters, insanity on acutal number processing and conversion,
insane array handling, no real optimization, or partial AST reduction, etc.., etc..).

Combines a lexer, parser, optimizer and a renderer. Can be invoked in any number of ways. Simplest is to use the sub this module exports,
liquid_render_file.

	use WWW::Shopify::Liquid qw/liquid_render_file/;
	
	$contents = liquid_render_file({ collection => { handle => "test" } }, "myfile.liquid");
	print $contents;
	
This is the simplest method. There are auxiliary methods which provide a lot of flexibility over how you render your
liquid (see below), and an OO interface.

This method represents the whole pipeline, so to get an overview of this module, we'll describe it here.
Fundamentally, what liquid_render_file does, is it slurps the whole file into a string, and then passes that string to
the lexer. This then generates a stream of tokens. These tokens are then transformed into an abstract syntax tree, by the
the parser if the syntax is valid. This AST represents the canonical form of the file, and can, from here, either
transformed back into almost the same file, statically optimized to remove any unecessary calls, or partially optimized to
remove branches of the tree for which you have variables to fill at this time, though both these steps are optional.

Finally, these tokens are passed to the renderer, which interprets the tokens and then produces a string representing the
final content that can be printed.

Has better error handling than Shopify's liquid processor, so if you use this to validate your liquid, you should get better
errors than if you're simply submitting them. This module is integrated into the L<Padre::Plugin::Shopify> module, so if you
use Padre as your Shopify IDE, you can automatically check the liquid of the file you're currently looking at with the click
of a button.

You can invoke each stage individually if you like.

	use WWW::Shopify::Liquid;
	my $text = ...
	my $liquid = WWW::Shopify::Liquid->new;
	my @tokens = $liquid->lexer->parse_text($text);
	my $ast = $liquid->parser->parse_tokens(@tokens);
	
	# Here we have a partial tree optimization. Meaning, if you have some of your
	# variables, but not all of them, you can simplify the template.
	$ast = $liquid->optimizer->optimize({ a => 2 }, $ast);
	
	# Finally, you can render.
	$result = $liquid->renderer->render({ b => 3 }, $ast);
	
If you're simply looking to check whether a liquid file is valid, you can do the following:

	use WWW::Shopify::Liquid qw/liquid_verify_file/;
	liquid_verify_file("my-snippet.liquid");
	
If sucessful, it'll return nothing, if it fails, it'll throw an exception, detailing the fault's location and description.

=cut

=head1 STATUS

This module is currently in beta. That means that while it is able to parse and validate liquid documents from Shopify, it may
be missing a few tags. In addition to this, the optimizer is not yet fully complete; it does not do advanced optimizations such as loop
unrolling. However, it does do partial tree rendering. Essentially what's missing is the ability to generate liquid from syntax trees.

This is close to complete, but not quite there yet. When done, this will be extremely beneficial to application proxies, as it will allow
the use of custom liquid syntax, with partial evaluation, before passing the remaining liquid back to Shopify for full evaluation. This
will allow you to do things like have custom tags that a user can customize which will be filled with your data, yet still allow Shopify to
evaluate stuff like asset_urls, includes, and whatnot.

=cut

use WWW::Shopify::Liquid::Parser;
use WWW::Shopify::Liquid::Optimizer;
use WWW::Shopify::Liquid::Lexer;
use WWW::Shopify::Liquid::Renderer;
use WWW::Shopify::Liquid::Operator;
use WWW::Shopify::Liquid::Tag;
use Scalar::Util qw(blessed);

sub new {
	my $package = shift;
	my $self = bless {
		filters => [],
		operators => [],
		tags => [],
		
		lexer => WWW::Shopify::Liquid::Lexer->new,
		parser => WWW::Shopify::Liquid::Parser->new,
		optimizer => WWW::Shopify::Liquid::Optimizer->new,
		renderer => WWW::Shopify::Liquid::Renderer->new,
		
		@_
	}, $package;
	
	$self->lexer->parent($self) if $self->lexer;
	$self->parser->parent($self) if $self->parser;
	$self->optimizer->parent($self) if $self->optimizer;
	$self->renderer->parent($self) if $self->renderer;
	
	$self->load_modules;
	
	return $self;
}

sub load_modules {
	my ($self) = @_;
	$self->register_operator($_) for (findallmod WWW::Shopify::Liquid::Operator);
	$self->register_filter($_) for (findallmod WWW::Shopify::Liquid::Filter);
	$self->register_tag($_) for (findallmod WWW::Shopify::Liquid::Tag);
}

sub lexer { return $_[0]->{lexer}; }
sub parser { return $_[0]->{parser}; }
sub optimizer { return $_[0]->{optimizer}; }
sub renderer { return $_[0]->{renderer}; }

sub register_tag {
	if (!$_[1]->abstract) {
		push(@{$_[0]->tags}, $_[1]);
		$_->register_tag($_[1]) for (grep { blessed($_) && $_->can('register_tag') } values(%{$_[0]}));
	}
}
sub register_filter {
	push(@{$_[0]->filters}, $_[1]);
	$_->register_filter($_[1]) for (grep { blessed($_) && $_->can('register_filter') } values(%{$_[0]}));
}
sub register_operator {
	WWW::Shopify::Liquid::Pipeline->register_operator($_[1]);
	push(@{$_[0]->operators}, $_[1]);
	$_->register_operator($_[1]) for (grep { blessed($_) && $_->can('register_operator') } values(%{$_[0]}));
}
sub tags { return $_[0]->{tags}; }
sub filters { return $_[0]->{filters}; }
sub operators { return $_[0]->{operators}; }
sub order_of_operations { return $_[0]->{order_of_operations}; }
sub free_tags { return $_[0]->{free_tags}; }
sub enclosing_tags { return $_[0]->{enclosing_tags}; }
sub processing_variables { return $_[0]->{processing_variables}; }
sub money_format { return $_[0]->{money_format}; }
sub money_with_currency_format { return $_[0]->{money_with_currency_format}; }
sub tag_list { return (keys(%{$_[0]->free_tags}), keys(%{$_[0]->enclosing_tags})); }

sub operate { return $_[0]->operators->{$_[3]}->($_[0], $_[1], $_[2], $_[4]); }

sub render_ast { my ($self, $hash, $ast) = @_; return $self->renderer->render($hash, $ast); }
sub unpack_ast { my ($self, $ast) = @_; return $self->parser->unparse_tokens($ast); }
sub unparse_text { my ($self, @tokens) = @_; return $self->lexer->unparse_text(@tokens); }
sub optimize_ast { my ($self, $hash, $ast) = @_; return $self->optimizer->optimize($hash, $ast); }
sub tokenize_text { my ($self, $text) = @_; return $self->lexer->parse_text($text); }
sub parse_tokens { my ($self, @tokens) = @_; return $self->parser->parse_tokens(@tokens); }
sub parse_text { my ($self, $text) = @_; return $self->parse_tokens($self->tokenize_text($text)); }

sub verify_text { my ($self, $text) = @_; $self->parse_tokens($self->parse_text($text)); }
sub verify_file { my ($self, $file) = @_; $self->verify_text(scalar(read_file($file))); }
sub render_text { my ($self, $hash, $text) = @_; return $self->render_ast($hash, $self->parse_tokens($self->tokenize_text($text))); }
sub render_file { 
	my ($self, $hash, $file) = @_;
	$self->lexer->file_context($file);
	$self->parser->file_context($file);
	$self->renderer->file_context($file);
	my @results = $self->render_text($hash, scalar(read_file($file)));
	$self->lexer->file_context(undef);
	$self->parser->file_context(undef);
	$self->renderer->file_context(undef);
	return $results[0] unless wantarray;
	return @results;
}

use Exporter;
use base 'Exporter';
our @EXPORT_OK = qw(liquid_render_file liquid_render_text liquid_verify_file liquid_verify_text);
sub liquid_render_text { my ($hash, $text) = @_; my $self = WWW::Shopify::Liquid->new; return $self->render_text($hash, $text); }
sub liquid_verify_text { my ($text) = @_; my $self = WWW::Shopify::Liquid->new; $self->verify_text($text); }
sub liquid_render_file { my ($hash, $file) = @_; my $self = WWW::Shopify::Liquid->new; return $self->render_file($hash, $file); }
sub liquid_verify_file { my ($file) = @_; my $self = WWW::Shopify::Liquid->new; $self->verify_file($file); }

sub liquify_item {
	my ($self, $item) = @_;
	die new WWW::Shopify::Liquid::Exception("Can only liquify shopify objects.") unless ref($item) && $item->isa('WWW::Shopify::Model::Item');
	
	my $fields = $item->fields();
	my $final = {};
	foreach my $key (keys(%$item)) {
		next unless exists $fields->{$key};
		if ($fields->{$key}->is_relation()) {
			if ($fields->{$key}->is_many()) {
				# Since metafields don't come prepackaged, we don't get them. Unless we've already got them.
				next if $key eq "metafields" && !$item->{metafields};
				my @results = $item->$key();
				if (int(@results)) {
					$final->{$key} = [map { $self->liquify_item($_) } @results];
				}
				else {
					$final->{$key} = [];
				}
			}
			if ($fields->{$key}->is_one() && $fields->{$key}->is_reference()) {
				if (defined $item->$key()) {
					# This is inconsistent; this if is a stop-gap measure.
					# Getting directly from teh database seems to make this automatically an id.
					if (ref($item->$key())) {
						$final->{$key} = $item->$key()->id();
					}
					else {
						$final->{$key} = $item->$key();
					}
				}
				else {
					$final->{$key} = undef;
				}
			}
			$final->{$key} = ($item->$key ? $item->$key->to_json() : undef) if ($fields->{$key}->is_one() && $fields->{$key}->is_own());
		} elsif (ref($fields->{$key}) !~ m/Date$/) {
			$final->{$key} = $fields->{$key}->to_shopify($item->$key);
		} else {
			$final->{$key} = $item->$key;
		}
	}
	return $final;
}


=head1 SEE ALSO

L<WWW::Shopify>, L<WWW::Shoipfy::Tools::Themer>, L<Padre::Plugin::Shopify>

=head1 AUTHOR

Adam Harrison (adamdharrison@gmail.com)

=head1 LICENSE

Copyright (C) 2016 Adam Harrison

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;