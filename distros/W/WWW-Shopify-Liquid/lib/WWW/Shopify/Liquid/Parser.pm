#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Liquid::Parser;
use base 'WWW::Shopify::Liquid::Pipeline';
use Module::Find;
use List::MoreUtils qw(firstidx part);
use List::Util qw(first);
use WWW::Shopify::Liquid::Exception;

useall WWW::Shopify::Liquid::Operator;
useall WWW::Shopify::Liquid::Tag;
useall WWW::Shopify::Liquid::Filter;

sub new { return bless {
	# Internal
	order_of_operations => [],
	operators => {},
	enclosing_tags => {},
	free_tags => {},
	filters => {},
	inner_tags => {},
	security => WWW::Shopify::Liquid::Security->new,
	
	# Determines whether or not we should error on finding a filter we don't recognize. Can be useful for parsing, without actually rendering ot have this on.
	# No tag version, because we need to know whether a tag is free or enclosing to parse correctly.
	accept_unknown_filters => 0,
	# Determines whether we clear the custom tag/filter cache after each parse. For security purposes, should be true by default,
	# or custom tags should be disabled entirely.
	transient_custom_operations => 1,
	custom_tags => {},
	custom_filters => {},
	transient_elements => []
}, $_[0]; }
sub accept_unknown_filters { $_[0]->{accept_unknown_filters} = $_[1] if defined $_[1]; return $_[0]->{accept_unknown_filters}; }
sub accept_method_calls { $_[0]->{accept_method_calls} = $_[1] if defined $_[1]; return $_[0]->{accept_method_calls}; }
sub transient_custom_operations { $_[0]->{transient_custom_operations} = $_[1] if defined $_[1]; return $_[0]->{transient_custom_operations}; }
sub custom_tags { return $_[0]->{custom_tags}; }
sub custom_filters { return $_[0]->{custom_filters}; }
sub operator { return $_[0]->{operators}->{$_[1]}; }
sub operators { return $_[0]->{operators}; }
sub order_of_operations { return @{$_[0]->{order_of_operations}}; }
sub free_tags { return $_[0]->{free_tags}; }
sub enclosing_tags { return $_[0]->{enclosing_tags}; }
sub inner_tags { return $_[0]->{inner_tags}; }
sub filters { return $_[0]->{filters}; }

sub register_tag {
	my ($self, $tag) = @_;
	$self->SUPER::register_tag($tag);
	$self->free_tags->{$tag->name} = $tag if $tag->is_free;
	if ($tag->is_enclosing) {
		$self->enclosing_tags->{$tag->name} = $tag;
		foreach my $inner_tag ($tag->inner_tags) {
			$self->inner_tags->{$inner_tag} = 1;
		}
	}
}

sub register_operator {
	$_[0]->SUPER::register_operator($_[1]);
	$_[0]->operators->{$_} = $_[1] for($_[1]->symbol);
	my $ooo = $_[0]->{order_of_operations};
	my $element = first { $_->[0]->priority == $_[1]->priority } @$ooo;
	if ($element) {
		push(@$element, $_[1]);
	}
	else {
		push(@$ooo, [$_[1]]);
	}
	$_[0]->{order_of_operations} = [sort { $b->[0]->priority <=> $a->[0]->priority } @$ooo];
}
sub register_filter {
	$_[0]->SUPER::register_filter($_[1]);
	$_[0]->filters->{$_[1]->name} = $_[1];
}

sub deregister_tag {
	my ($self, $tag) = @_;
	$self->SUPER::deregister_tag($tag);
	if ($tag->is_enclosing) {
		delete $self->enclosing_tags->{$tag->name} if $self->enclosing_tags->{$tag->name};
		foreach my $inner_tag ($tag->inner_tags) {
			delete $self->inner_tags->{$inner_tag} if $self->inner_tags->{$inner_tag};
		}
	} else {
		delete $self->free_tags->{$tag->name} if $self->free_tags->{$tag->name};
	}
}
sub deregister_filter {
	my ($self, $filter) = @_;
	$self->SUPER::deregister_filter($filter);
	delete $self->filters->{$filter->name} if $self->filters->{$filter->name};
}


sub parse_filter_tokens {
	my ($self, $initial, @tokens) = @_;
	my $filter = shift(@tokens);
	my $filter_name = $filter->isa('WWW::Shopify::Liquid::Token::Operator') ? $filter->{core} : $filter->{core}->[0]->{core};
	# TODO God, this is stupid, but temporary patch.
	my $filter_package;
	if ($filter_name =~ m/::/) {
		$filter_package = $filter_name;
		eval { $filter_package->name };
		if ($@) {
			die new WWW::Shopify::Liquid::Exception::Parser::UnknownFilter($filter) if !$self->accept_unknown_filters;
			$filter_package = 'WWW::Shopify::Liquid::Filter::Unknown';
		}
	} else {
		if (!$self->{filters}->{$filter_name}) {
			die new WWW::Shopify::Liquid::Exception::Parser::UnknownFilter($filter) if !$self->accept_unknown_filters;
			$filter_package = 'WWW::Shopify::Liquid::Filter::Unknown';
		} else {
			$filter_package = $self->{filters}->{$filter_name};
		}
	}
	die new WWW::Shopify::Liquid::Exception::Parser::Arguments($filter, "In order to have arguments, filter must be followed by a colon.") if int(@tokens) > 0 && $tokens[0]->{core} ne ":";
	
	my @arguments = ();
	# Get rid of our colon.
	if (shift(@tokens)) {
		my $i = 0;
		@arguments = map { $self->parse_argument_tokens(grep { !$_->isa('WWW::Shopify::Liquid::Token::Separator') } @{$_}) } part { $i++ if $_->isa('WWW::Shopify::Liquid::Token::Separator') && $_->{core} eq ","; $i; } @tokens;
	}
	$filter = $filter_package->new($self, $filter->{line}, $filter_name, $initial, @arguments);
	$filter->verify($self);
	return $filter;
}
use List::MoreUtils qw(part);

sub walk_groupings {
	my ($self, $aggregate) = @_;
	for (grep { 
		$aggregate->{members}->[$_]->isa('WWW::Shopify::Liquid::Token::Grouping')
	} 0..(int(@{$aggregate->{members}})-1)) {
		($aggregate->{members}->[$_]) = $self->parse_argument_tokens($aggregate->{members}->[$_]->members);
	}
	$self->walk_groupings($_) for (grep { $_->isa('WWW::Shopify::Liquid::Token::Hash') || $_->isa('WWW::Shopify::Liquid::Token::Array') } $aggregate->members);
	
}

# Similar, but doesn't deal with tags; deals solely with order of operations.
sub parse_argument_tokens {
	my ($self, @argument_tokens) = @_;
	
	# Process all function calls. That means groupings, preceded by a varialbe.	
	my @ids = grep {
		$argument_tokens[$_]->isa('WWW::Shopify::Liquid::Token::Variable') && $argument_tokens[$_+1]->isa('WWW::Shopify::Liquid::Token::Grouping')
	} (0..$#argument_tokens-1);
	for (@ids) {
		$argument_tokens[$_] = WWW::Shopify::Liquid::Token::FunctionCall->new($argument_tokens[$_]->{line}, pop(@{$argument_tokens[$_]->{core}}), $argument_tokens[$_], $self->parse_argument_tokens($argument_tokens[$_+1]->members));
		$argument_tokens[$_+1] = undef;
	}
	@argument_tokens = grep { defined $_ } @argument_tokens;
	
	# Process all groupings.
	($argument_tokens[$_]) = $self->parse_argument_tokens($argument_tokens[$_]->members) for (grep { $argument_tokens[$_]->isa('WWW::Shopify::Liquid::Token::Grouping') } 0..$#argument_tokens);
	
	# Process all groupings inside named variables.
	($_->{core}) = $self->parse_argument_tokens($_->{core}->members) for (grep { $_->isa('WWW::Shopify::Liquid::Token::Variable::Named') && $_->{core}->isa('WWW::Shopify::Liquid::Token::Grouping') } @argument_tokens);
	# Preprocess all variant filters.
	for my $variable (grep { $_->isa('WWW::Shopify::Liquid::Token::Variable') } @argument_tokens) {
		my @core = @{$variable->{core}};
		($variable->{core}->[$_]) = $self->parse_argument_tokens($core[$_]->members) for (grep { $core[$_]->isa('WWW::Shopify::Liquid::Token::Grouping') } 0..$#core);
	}
	
	# Every member that's a grouping inside of the hash should be evaluated.
	$self->walk_groupings($_) for (grep { $_->isa('WWW::Shopify::Liquid::Token::Hash') || $_->isa('WWW::Shopify::Liquid::Token::Array') } @argument_tokens);
	
	# Process unary operators first; these have highest priority, regardless of what the priority field says.
	while ((my $idx = firstidx { $_->isa('WWW::Shopify::Liquid::Token::Operator') && defined $_->{core} && $self->operator($_->{core}) && $self->operator($_->{core})->arity eq "unary" } @argument_tokens) != -1) {
		my $op = $argument_tokens[$idx];
		my $fixness = $self->operator($argument_tokens[$idx]->{core})->fixness;
		my $op1 = $fixness eq "postfix" ? $argument_tokens[$idx-1] : $argument_tokens[$idx+1];
		my $start =  $fixness eq "potsfix" ? $idx-1 : $idx;
		splice(@argument_tokens, $start, 2, $self->operator($argument_tokens[$idx]->{core})->new($op->{line}, $op->{core}, $op1));
	}
	
	# First, pull together filters. These are the highest priority operators, after parentheses. They also have their own weird syntax.
	my $top = undef;
	
	# Don't partition if we have any pipes. Pipes and multiple arguments don't play well together.
	my @partitions;
	my $has_pipe = 0;
	if (int(grep { $_->isa('WWW::Shopify::Liquid::Token::Operator') && $_->{core} eq "|" } @argument_tokens) == 0)  {
		my $i = 0;
		$has_pipe = 1;
		@partitions = part { $i++ if $_->isa('WWW::Shopify::Liquid::Token::Separator'); $i; } @argument_tokens;
		@partitions = map { my @n = grep { !$_->isa('WWW::Shopify::Liquid::Token::Separator') } @$_; \@n } @partitions;
	} else {
		@partitions = (\@argument_tokens);
	}
	
	
	
	my @tops;
	
	
	
	foreach my $partition (@partitions) {
		my @tokens = @$partition;
		#@tokens = (grep { !$_->isa('WWW::Shopify::Liquid::Token::Separator') } @tokens) if !$has_pipe;
		
		# Use the order of operations to create a binary tree structure.
		foreach my $operators ($self->order_of_operations) {
			my %ops = map { $_ => 1 } map { $_->symbol } @$operators;
			# If we have pipes, we deal with those, and parse their lower level arguments first; this is an exception. Rewrite?
			if ($operators->[0] eq 'WWW::Shopify::Liquid::Operator::Pipe') {
				if ((my $idx = firstidx { $_->isa('WWW::Shopify::Liquid::Token::Operator') && $_->{core} eq "|" } @tokens) != -1) {
					die new WWW::Shopify::Liquid::Exception::Parser($tokens[0]) if $idx == 0;
					my $i = 0;
					# Part should consist of the first token before a pipe, and then split on all pipes after this.,
					my @parts = map { shift(@{$_}) if $_->[0]->{core} && $_->[0]->{core} eq "|"; $_ } part { $i++ if $_->isa('WWW::Shopify::Liquid::Token::Operator') && $_->{core} eq "|"; $i; } splice(@tokens, $idx-1);
					my $next = undef;
					$top = $self->parse_filter_tokens($self->parse_argument_tokens(@{shift(@parts)}), @{shift(@parts)});
					while (my $part = shift(@parts)) {
						$top = $self->parse_filter_tokens($top, @$part);
					}
					push(@tokens, $top);
				}
			} else {
				while ((my $idx = firstidx { $_->isa('WWW::Shopify::Liquid::Token::Operator') && exists $ops{$_->{core}} } @tokens) != -1) {
					my ($op1, $op, $op2) = @tokens[$idx-1..$idx+1];
					# The one exception would be if we have a - operator, and nothing before, this is unary negative operator, i.e. 0 - number.
					die new WWW::Shopify::Liquid::Exception::Parser::Operands($op, $op1, $op, $op2) unless
						$idx > 0 && $idx < $#tokens && 
						($op1->isa('WWW::Shopify::Liquid::Operator') || $op1->isa('WWW::Shopify::Liquid::Token::Operand') || $op1->isa('WWW::Shopify::Liquid::Filter')) &&
						($op2->isa('WWW::Shopify::Liquid::Operator') || $op2->isa('WWW::Shopify::Liquid::Token::Operand') || $op2->isa('WWW::Shopify::Liquid::Filter'));
					($op1) = $self->parse_argument_tokens($op1->members) if $op1->isa('WWW::Shopify::Liquid::Token::Grouping');
					($op2) = $self->parse_argument_tokens($op2->members) if $op2->isa('WWW::Shopify::Liquid::Token::Grouping');
					splice(@tokens, $idx-1, 3, $self->operators->{$op->{core}}->new($op->{line}, $op->{core}, $op1, $op2));
				}
			}
		}
		
		# Only named variables can be without commas, for whatever reason. Goddammit shopify.
		die new WWW::Shopify::Liquid::Exception::Parser::Operands(@tokens) unless int(grep { !$_->isa('WWW::Shopify::Liquid::Token::Variable::Named') } @tokens) == 1 || int(grep { !$_->isa('WWW::Shopify::Liquid::Token::Variable::Named') } @tokens) == 0;
		push(@tops, @tokens);
	}	
	
	return @tops;
}


sub parse_inner_tokens {
	my ($self, @tokens) = @_;
	
	return () if int(@tokens) == 0;
	
	my @tags = ();	
	# First we take a look and start matching up opening and ending tags. Those which are free tags we can leave as is.
	while (my $token = shift(@tokens)) {
		my $line = $token->{line};
		if ($token->isa('WWW::Shopify::Liquid::Token::Tag')) {
			my $tag = undef;
			if ($self->enclosing_tags->{$token->tag}) {
				my @internal = ();
				my @contents = ();
				my %allowed_internal_tags = map { $_ => 1 } $self->enclosing_tags->{$token->tag}->inner_tags;
				my $level = 1;
				my $closed = undef;
				for (0..$#tokens) {
					if ($tokens[$_]->isa('WWW::Shopify::Liquid::Token::Tag')) {
						if ($self->enclosing_tags->{$tokens[$_]->tag}) {
							++$level;
						} elsif (exists $allowed_internal_tags{$tokens[$_]->tag} && $level == 1) {
							$tokens[$_]->{arguments} = [$self->parse_argument_tokens(@{$tokens[$_]->{arguments}})];
							push(@internal, $_);
						} elsif ($tokens[$_]->tag eq "end" . $token->tag && $level == 1) {
							--$level;
							my $last_int = 0;
							foreach my $int (@internal, $_) {
								push(@contents, [splice(@tokens, 0, $int-$last_int)]);
								shift(@{$contents[0]}) if $self->enclosing_tags->{$token->tag}->inner_ignore_whitespace && int(@contents) > 0 && int(@{$contents[0]}) > 0 && $contents[0]->[0]->isa('WWW::Shopify::Liquid::Token::Text::Whitespace');
								@contents = map {
									my @array = @$_;
									if (int(@array) > 0 && $array[0]->isa('WWW::Shopify::Liquid::Token::Tag') && $allowed_internal_tags{$array[0]->tag}) {
										[$array[0], $self->parse_inner_tokens(@array[1..$#array])];
									}
									else {
										[$self->parse_inner_tokens(@array)]
									}
								} @contents;
								$last_int = $int;
							}
							# Remove the endtag.
							shift(@tokens);
							$closed = 1;
							last;
						} elsif ($tokens[$_]->tag =~ m/^end/) {
							--$level;
							# TODO: Fix this whole thing; right now, no close tags are being spit out for the wrong tag. We do this to avoid an {% unless %}{% if %}{% else %}{% endif %}{% endunless%} situtation.
						}
					}
				}
				die new WWW::Shopify::Liquid::Exception::Parser::NoClose($token) unless $closed;
				$tag = $self->enclosing_tags->{$token->tag}->new($line, $token->tag, [$self->parse_argument_tokens(@{$token->{arguments}})], \@contents, $self);
				$tag->verify($self);
			}
			elsif ($self->free_tags->{$token->tag}) {
				$tag = $self->free_tags->{$token->tag}->new($line, $token->tag, [$self->parse_argument_tokens(@{$token->{arguments}})], undef, $self);
				$tag->verify($self);
			}
			else {
				die new WWW::Shopify::Liquid::Exception::Parser::NoOpen($token) if ($token->tag =~ m/^end(\w+)$/ && $self->enclosing_tags->{$1});
				die new WWW::Shopify::Liquid::Exception::Parser::NakedInnerTag($token) if (exists $self->inner_tags->{$token->tag});
				die new WWW::Shopify::Liquid::Exception::Parser::UnknownTag($token);
			}
			push(@tags, $tag);
		}
		elsif ($token->isa('WWW::Shopify::Liquid::Token::Output')) {
			push(@tags, WWW::Shopify::Liquid::Tag::Output->new($line, [$self->parse_argument_tokens(@{$token->{core}})]));
		}
		else {
			push(@tags, $token);
		}
	}
	
	my $top = undef;
	if (int(@tags) > 1) {
		$top = WWW::Shopify::Liquid::Operator::Concatenate->new($tags[0]->{line}, '', @tags);
	}
	else {
		($top) = @tags;
	}
	return $top;
}

sub parse_tokens {
	my ($self, @tokens) = @_;
	my $ast = $self->parse_inner_tokens(@tokens);
	for (@{$self->{transient_elements}}) {
		if ($_->isa('WWW::Shopify::Liquid::Tag')) {
			$self->deregister_tag($_);
		} elsif ($_->isa('WWW::Shopify::Liquid::Filter')) {
			$self->deregister_filter($_);
		}
	}
	$self->{transient_elements} = [];
	return $ast;
}

sub unparse_argument_tokens {
	my ($self, $ast) = @_;
	return $ast if $self->is_processed($ast);
	if ($ast->isa('WWW::Shopify::Liquid::Filter')) {
		my @optokens = ($self->unparse_argument_tokens($ast->{operand}), 
			WWW::Shopify::Liquid::Token::Operator->new([0,0,0], '|'),
			($ast->transparent ? WWW::Shopify::Liquid::Token::Variable->new([0,0,0], WWW::Shopify::Liquid::Token::String->new([0,0,0], $ast->{core}->name)) : WWW::Shopify::Liquid::Token::Variable->new([0,0,0], WWW::Shopify::Liquid::Token::String->new([0,0,0], $ast->{core}))),
			(int(@{$ast->{arguments}}) > 0 ? (do {
				my @args = @{$ast->{arguments}};
				(
					WWW::Shopify::Liquid::Token::Separator->new([0,0,0], ':'), 
					(map { (($_ > 0 ? (WWW::Shopify::Liquid::Token::Separator->new([0,0,0], ',')) : ()), $self->unparse_argument_tokens($args[$_])) } 0..$#args)
				)
			}) : ())
		);
		return @optokens;
	} elsif ($ast->isa('WWW::Shopify::Liquid::Operator')) {
		my @optokens = ($self->unparse_argument_tokens($ast->{operands}->[0]), WWW::Shopify::Liquid::Token::Operator->new([0,0,0], $ast->{core}), $self->unparse_argument_tokens($ast->{operands}->[1]));
		return WWW::Shopify::Liquid::Token::Grouping->new([0,0,0], @optokens) if $ast->requires_grouping;
		return @optokens;
	} else {
		return $ast;
	}
}

sub unparse_tokens {
	my ($self, $ast) = @_;
	return $ast if $self->is_processed($ast) || $ast->isa('WWW::Shopify::Liquid::Token');
	if ($ast->isa('WWW::Shopify::Liquid::Tag')) {
		my @arguments = $ast->{arguments} ? $self->unparse_argument_tokens(@{$ast->{arguments}}) : ();
		if ($ast->isa('WWW::Shopify::Liquid::Tag::Enclosing')) {
			if ($ast->isa('WWW::Shopify::Liquid::Tag::If')) {
				return (WWW::Shopify::Liquid::Token::Tag->new([0,0,0], $ast->{core}, \@arguments), $self->unparse_tokens($ast->{true_path}), WWW::Shopify::Liquid::Token::Tag->new([0,0,0], 'end' . $ast->{core})) if !$ast->{false_path};
				if ($ast->{false_path}->isa('WWW::Shopify::Liquid::Tag::If')) {
					# Untangle the thing, and spread out in an array all if statement that have if statements as their false_paths.
					my @elsifs;
					my $recursive;
					$recursive = sub {
						my ($ast) = @_;
						push(@elsifs, WWW::Shopify::Liquid::Token::Tag->new([0,0,0], 'elsif', ($ast->{arguments} ? [$self->unparse_argument_tokens(@{$ast->{arguments}})] : [])), $self->unparse_tokens($ast->{true_path}));
						if ($ast->{false_path} && $ast->{false_path}->isa('WWW::Shopify::Liquid::Tag::If')) {
							$recursive->($ast->{false_path});
						} elsif ($ast->{false_path}) {
							push(@elsifs, WWW::Shopify::Liquid::Token::Tag->new([0,0,0], 'else'), $self->unparse_tokens($ast->{false_path}));
						}
					};
					$recursive->($ast->{false_path});
					return (WWW::Shopify::Liquid::Token::Tag->new([0,0,0], $ast->{core}, \@arguments), $self->unparse_tokens($ast->{true_path}), @elsifs, WWW::Shopify::Liquid::Token::Tag->new([0,0,0], 'end'. $ast->{core}));
				}
				return (WWW::Shopify::Liquid::Token::Tag->new([0,0,0], $ast->{core}, \@arguments), $self->unparse_tokens($ast->{true_path}), WWW::Shopify::Liquid::Token::Tag->new([0,0,0], 'else'), $self->unparse_tokens($ast->{false_path}), WWW::Shopify::Liquid::Token::Tag->new([0,0,0], 'end'. $ast->{core}));
			}
			else {
				return (WWW::Shopify::Liquid::Token::Tag->new([0,0,0], $ast->{core}, \@arguments), $self->unparse_tokens($ast->{contents}), WWW::Shopify::Liquid::Token::Tag->new([0,0,0], 'end' . $ast->{core}));
			}
		}
		elsif ($ast->isa('WWW::Shopify::Liquid::Tag::Output')) {
			return (WWW::Shopify::Liquid::Token::Output->new([0,0,0], [$self->unparse_argument_tokens(@{$ast->{arguments}})]));
		}
		else  {
			return (WWW::Shopify::Liquid::Token::Tag->new([0,0,0], $ast->{core}, \@arguments));
		}
		return $ast;
	}
	if ($ast->isa('WWW::Shopify::Liquid::Filter')) {
		return $ast;
	}
	return (map { $self->unparse_tokens($_) } @{$ast->{operands}}) if ($ast->isa('WWW::Shopify::Liquid::Operator::Concatenate'));
	
}

1;